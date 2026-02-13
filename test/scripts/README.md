## Histograms

The `sail-mnemonic-histogram*` scripts help the user analyze tests by creating 
histograms of instruction mnemonics. 

`TODO:` Build upon these scripts, e.g., 
1. To find out if a test suite has coverage holes, i.e., if it does **not** 
   cover all of the mnemonics in a group of instructions such as a RISC-V 
   extension.
2. To sort the tests according to the number of mnemonics used.
3. To get the union of all mnemonics belonging to a certain pattern.
