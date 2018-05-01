DictionaryDuplicates = {
    metadata = {
        description = "The test finds duplicates across all dictionaries used for testing.",
        authors = "Lana Ovcharenko",
        emails = "lovchare@redhat.com",
        changed = "2018-04-30",
        tags = {"DocBook", "Release"}
    },    
    requires = {"wget"},
    aspellFile = "aspell.txt",
    blacklistUrl = "ccs-apps.gsslab.brq.redhat.com/zw/blacklist/text",
    whitelistUrl = "ccs-apps.gsslab.brq.redhat.com/zw/whitelist/text",
    glossaryUrl = "ccs-apps.gsslab.brq.redhat.com/zw/glossary/json",
    aspell = nil,
    aspellLowercase = nil,
    glossaryTables = nil,
    glossary = nil,
    glossaryLowercase = nil,
    whitelist = nil,
    whitelistLowercase = nil,
    blacklist = nil,
    blacklistLowercase = nil,
    testDir = nil,
}



-- Entry point for the test.
function DictionaryDuplicates.setUp()
    DictionaryDuplicates:loadDictionaries()
end



function DictionaryDuplicates:loadDictionaries()
    self.testDir = getTestDir()
    self.aspell, self.aspellLowercase = self:getAspell()
    self.glossaryTables = self:getGlossary()
    self.glossary, self.glossaryLowercase = self:processGlossary()
    self.whitelist, self.whitelistLowercase = self:getWhitelist()
    self.blacklist, self.blacklistLowercase = self:getBlacklist()
end



function DictionaryDuplicates:getAspell()
    local words = {}
    local wordsLowercase = {}
    local input = io.open(self.testDir .. self.aspellFile, "r")
    if not input then
        fail("Cannot open Aspell: " .. self.testDir .. self.aspellFile)
        return {}
    end
    for line in input:lines() do
        words[line:trimString()] = (words[line:trimString()] or 0) + 1
        local countLowercase = 1
        if wordsLowercase[line:trimString():lower()] then
            countLowercase = wordsLowercase[line:trimString():lower()].count
        end
        wordsLowercase[line:trimString():lower()] = {original=line:trimString(), count=countLowercase}
    end
    input:close()
    return words, wordsLowercase
end



function DictionaryDuplicates:getGlossary()
    local file = self.testDir .. "glossary.json"
    downloadData(self.glossaryUrl, file)
    local words = readInputFile(file)
    if not words then
        return {}
    end
    return words
end



function DictionaryDuplicates:processGlossary()
    local words = {}
    local wordsLowercase = {}
    for _, t in ipairs(self.glossaryTables) do
        words[t.word:trimString()] = (words[t.word:trimString()] or 0) + 1
        local countLowercase = 1
        if wordsLowercase[t.word:trimString():lower()] then
            countLowercase = wordsLowercase[t.word:trimString():lower()].count
        end
        wordsLowercase[t.word:trimString():lower()] = {original=t.word:trimString(), count=countLowercase}
    end
    return words, wordsLowercase
end



function DictionaryDuplicates:getWhitelist()
    local file = self.testDir .. "whitelist.txt"
    downloadData(self.whitelistUrl, file)
    local words = {}
    local wordsLowercase = {}
    local input = io.open(file, "r")
    if not input then
        return {}
    end
    for line in input:lines() do
        words[line:trimString()] = (words[line:trimString()] or 0) + 1
        local countLowercase = 1
        if wordsLowercase[line:trimString():lower()] then
            countLowercase = wordsLowercase[line:trimString():lower()].count
        end
        wordsLowercase[line:trimString():lower()] = {original=line:trimString(), count=countLowercase}
    end
    input:close()
    return words, wordsLowercase
end



function DictionaryDuplicates:getBlacklist()
    local file = self.testDir .. "blacklist.txt"
    downloadData(self.blacklistUrl, file)
    local words = {}
    local wordsLowercase = {}
    local input = io.open(file, "r")
    if not input then
        return {}
    end
    for line in input:lines() do
        local i = line:find("\t")
        local word = ""
        if i then
            word = line:sub(1, i - 1):trimString()
        else
            word = line:trimString()
        end
        words[word] = (words[word] or 0) + 1
        local countLowercase = 1
        if wordsLowercase[word:lower()] then
            countLowercase = wordsLowercase[word:lower()].count
        end
        wordsLowercase[word:lower()] = {original=word, count=countLowercase}
    end
    input:close()
    return words, wordsLowercase
end



function readInputFile(file)
    local string = readInputFileAsString(file)
    if not string then
        return nil
    end
    return json.decode(string, 1, nil)
end



function readInputFileAsString(file)
    local input = io.open(file, "r")
    if not input then
       warn("Cannot open file: " .. file)
       return nil
    end
    local string = input:read("*all")
    input:close()
    return string
end



function downloadData(url, file)
    if not url then
        return
    end
    local command = "wget -O " .. file .. " " .. url .. "> /dev/null 2>&1"
    os.execute(command)
end



function getTestDir()
    local path = debug.getinfo(1).source
    if path:startsWith("@") then
        path = path:sub(2, path:lastIndexOf("/"))
    end
    return path
end



function DictionaryDuplicates:checkCrossMatches(aspell, blacklist, whitelist, glossary, isLowercase)
    local duplicates = {}
    if not isLowercase then
        for w, _ in pairs(glossary) do
            if aspell[w] and blacklist[w] and whitelist[w] then
                duplicates[w] = ": glossary + aspell + blacklist + whitelist"
            elseif blacklist[w] and whitelist[w] then
                duplicates[w] = ": glossary + blacklist + whitelist"
            elseif aspell[w] and blacklist[w] then
                duplicates[w] = ": glossary + aspell + blacklist"
            elseif aspell[w] and whitelist[w] then
                duplicates[w] = ": glossary + aspell + whitelist"
            elseif blacklist[w] then
                duplicates[w] = ": glossary + blacklist"
            elseif whitelist[w] then
                duplicates[w] = ": glossary + whitelist"
            elseif aspell[w] then
                duplicates[w] = ": glossary + aspell"
            end
        end
    else
        for w, table in pairs(glossary) do
            if not duplicates[table.original] then
                if aspell[w] and blacklist[w] and whitelist[w] then
                    duplicates[w] = " (lowercase): glossary + aspell + blacklist + whitelist"
                elseif blacklist[w] and whitelist[w] then
                    duplicates[w] = " (lowercase): glossary + blacklist + whitelist"
                elseif aspell[w] and blacklist[w] then
                    duplicates[w] = " (lowercase): glossary + aspell + blacklist"
                elseif aspell[w] and whitelist[w] then
                    duplicates[w] = " (lowercase): glossary + aspell + whitelist"
                elseif blacklist[w] then
                    duplicates[w] = " (lowercase): glossary + blacklist"
                elseif whitelist[w] then
                    duplicates[w] = " (lowercase): glossary + whitelist"
                elseif aspell[w] then
                    duplicates[w] = " (lowercase): glossary + aspell"
                end
            end
        end
    end
    return duplicates
end



function DictionaryDuplicates:checkGlossaryDuplicates()
    local duplicates = {}
    local duplicatesLowercase = {}
    for w, count in pairs(self.glossary) do
        if count > 1 then
            duplicates[w] = ": " .. count
        end
    end
    for w, table in pairs(self.glossaryLowercase) do
        if table.count > 1 and not duplicates[table.original] then
            duplicatesLowercase[table.original] = " (lowercase): " .. table.count
        end
    end
    return duplicates, duplicatesLowercase
end



-- Test for duplicates across all dictionaries.
function DictionaryDuplicates.testDictionaryDuplicates()
    local glossaryDuplicates, glossaryDuplicatesLowercase = DictionaryDuplicates:checkGlossaryDuplicates()
    if glossaryDuplicates or glossaryDuplicatesLowercase then
        print("GLOSSARY DUPLICATES:")
    end
    for w, location in pairs(glossaryDuplicates) do
        fail(w .. location)
    end
    for w, location in pairs(glossaryDuplicatesLowercase) do
        warn(w .. location)
    end
    local crossMatches = DictionaryDuplicates:checkCrossMatches(
        DictionaryDuplicates.aspell, 
        DictionaryDuplicates.blacklist, 
        DictionaryDuplicates.whitelist, 
        DictionaryDuplicates.glossary, 
        false)
    local crossMatchesLowercase = DictionaryDuplicates:checkCrossMatches(
        DictionaryDuplicates.aspellLowercase, 
        DictionaryDuplicates.blacklistLowercase, 
        DictionaryDuplicates.whitelistLowercase, 
        DictionaryDuplicates.glossaryLowercase, 
        true)
    if crossMatches or crossMatchesLowercase then
        print("CROSS-MATCHES:")
    end
    for w, location in pairs(crossMatches) do
        fail(w .. location)
    end
    for w, location in pairs(crossMatchesLowercase) do
        warn(w .. location)
    end
end