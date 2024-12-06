import math


results=[0,0] #The values for boards of size 0 and 1


for i in range(2,500): #The second number determines how large of a board size to calculate up to.
    options=set()#Empty set of options which we will populate
    for j in range(0,math.ceil(i/2)): #We check the first half of the options, the rest are symmetrically the same.

        options.add(results[j]^results[i-1-j])#The value of each option is found by applying xor to the values of the boards after the split.
        
    mex=0 #We calculate the mex by checking integers until we find one that isn't an option.
    while mex in options:
        mex+=1
    results.append(mex) #records the value in results

    #if mex==0:
    #    print(i)

for i in range(len(results)):
        print(i,results[i])
        
        

    
        
   
