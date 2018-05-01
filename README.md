# emender-dictionary-duplicates

## What is it?
This is an [Emender](https://github.com/emender/emender) test to find duplicate words across multiple dictionaries: glossary, aspell, whitelist and blacklist.

## How to run it?
To run the test locally, follow these steps.
1. Download the repository to your local machine.
2. Before running the test make sure to install Aspell dictionary.
~~~~~~~~
sudo dnf install aspell	
~~~~~~~~ 
Once it's installed, run the script "generate_dictionary.sh" in the test folder. It will generate "aspell.txt" with the dictionary words.
3. You'll also need Lua installed.
~~~~~~~~
sudo dnf install lua
~~~~~~~~
4. One of the other dependencies is wget, but most Linux dostributions have it by default.
~~~~~~~~
sudo dnf install wget
~~~~~~~~
5. You're ready to run the tests! Type this command into your Terminal window:
~~~~~~~~
emend path_to_your_test_folder/DictionaryDuplicates.lua
~~~~~~~~
6. You can check available Emender parameters [here](https://github.com/emender/emender/blob/master/doc/man/man1/emend.1.pod).