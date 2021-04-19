import json
import argparse
import csv
from web3 import Web3
from pprint import pprint
import os

# -----------------------------------------------------

parser = argparse.ArgumentParser(description='Esegui il test RS.')
parser.add_argument('--build', type=str,
						default='build/contracts/DART.json',
						help="path all'artifact DART.json prodotto da Truffle a seguito della compilazione (default: build/contracts/DART.json)")
parser.add_argument('--host', type=str,
						default='http://localhost:8545',
						help="hostname e porta della blockchain su cui è stato deployato DART (default: http://localhost:8545)")
parser.add_argument('--netid', type=int,
						default=1,
						help="network id della blockchain (default: 1)")
parser.add_argument(dest='n_eligibles', type=int, help='numero di principal da registrare come esperti')
parser.add_argument(dest='n_universities', type=int, help='numero di università da istanziare e su cui smistare gli studenti')
args = parser.parse_args()

nEligibles = args.n_eligibles
nUniversities = args.n_universities
totGas=0

# Inizializza web3 connettendolo al provider locale ganache
w3 = Web3(Web3.HTTPProvider(args.host))
accounts = w3.eth.accounts;
w3.eth.defaultAccount = accounts[0]

if len(accounts) < (3+nEligibles+nUniversities):
	print("Not enough available Ethereum accounts! At least (N_eligibles + N_universities + 3) accounts are needed in order to run this test")
	sys.exit(-1)

nEligiblesBuyer= nEligibles
nEligibleExpert= nEligibles//2
addressesOfEligiblesBuyer = accounts[3:3+nEligiblesBuyer]
addressesOfEligiblesExpert = accounts[3:3+nEligibleExpert]
addressesOfEligibles = accounts[3:3+nEligibles]
addressesOfUniversities = accounts[3+nEligibles:3+nEligibles+nUniversities]

# Inizializza l'interfaccia per interagire con lo smart contract DART
DARTArtifact = json.load(open(args.build))
contract = w3.eth.contract(abi=DARTArtifact['abi'], address=DARTArtifact['networks'][str(args.netid)]['address'])

PR = {
	'Alice': accounts[0],
	'RecSys': accounts[1],
	'StateA': accounts[2]
}
for idx, addr in enumerate(addressesOfEligibles):
	PR['Principal[' + str(idx+1) + ']'] = addr
for idx, addr in enumerate(addressesOfUniversities):
	PR['Uni[' + str(idx+1) + ']'] = addr
INV_PR = {v: k for k, v in PR.items()}
print("\nPRINCIPALS:")
pprint(PR)

# ... rolenames esadecimali a rolenames stringhe e viceversa
RN = {
	'recommendationFrom': '0x000a',
	'reviewer': '0x000b',
	'expert': '0x000c',
	'university': '0x000d',
	'buyer': '0x000e',
	'professor': '0x000f'
}
INV_RN = {v: k for k, v in RN.items()}
print("\nROLENAMES:")
pprint(RN)

operations = {'newRole':[],'simpleMember':[],'simpleInclusion':[],'linkedInclusion':[],'intersectionInclusion':[]}

# -----------------------------------------------------

# Registra ruoli e credenziali per istanziare la policy di test EPapers
print("Loading policy... ", end='')

contract.functions.newRole(RN['recommendationFrom']).call({'from': PR['Alice']})
txHash = contract.functions.newRole(RN['recommendationFrom']).transact({'from': PR['Alice']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("newRole mined:")
pprint(dict(receipt))
operations['newRole'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

contract.functions.newRole(RN['reviewer']).call({'from': PR['RecSys']})
txHash = contract.functions.newRole(RN['reviewer']).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("newRole mined:")
pprint(dict(receipt))
operations['newRole'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

contract.functions.newRole(RN['expert']).call({'from': PR['RecSys']})
txHash = contract.functions.newRole(RN['expert']).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("newRole mined:")
pprint(dict(receipt))
operations['newRole'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

contract.functions.newRole(RN['buyer']).call({'from': PR['RecSys']})
txHash = contract.functions.newRole(RN['buyer']).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("newRole mined:")
pprint(dict(receipt))
operations['newRole'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

contract.functions.newRole(RN['university']).call({'from': PR['RecSys']})
txHash = contract.functions.newRole(RN['university']).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("newRole mined:")
pprint(dict(receipt))
operations['newRole'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

contract.functions.newRole(RN['professor']).call({'from': PR['RecSys']})
txHash = contract.functions.newRole(RN['professor']).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("newRole mined:")
pprint(dict(receipt))
operations['newRole'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

contract.functions.newRole(RN['university']).call({'from': PR['StateA']})
txHash = contract.functions.newRole(RN['university']).transact({'from': PR['StateA']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("newRole mined:")
pprint(dict(receipt))
operations['newRole'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

for uniAddr in addressesOfUniversities:
	contract.functions.newRole(RN['professor']).call({'from': uniAddr})
	txHash = contract.functions.newRole(RN['professor']).transact({'from': uniAddr})
	receipt=w3.eth.waitForTransactionReceipt(txHash)
	print("newRole mined:")
	pprint(dict(receipt))
	operations['newRole'].append(receipt['gasUsed'])
	totGas += receipt['gasUsed']

for idx, principalAddr in enumerate(addressesOfEligiblesExpert):
	# Registra il principal come professore di una delle università
	#d.addSimpleMember(RN['professor'], SMExpression(principalAddr), 100, {'from': addressesOfUniversities[idx % len(addressesOfUniversities)]})
	contract.functions.addSimpleMember(RN['professor'],principalAddr,100).call({'from': addressesOfUniversities[idx % len(addressesOfUniversities)]})
	txHash = contract.functions.addSimpleMember(RN['professor'],principalAddr,100).transact({'from': addressesOfUniversities[idx % len(addressesOfUniversities)]})
	receipt=w3.eth.waitForTransactionReceipt(txHash)
	print("SimpleMember mined:")
	pprint(dict(receipt))
	operations['simpleMember'].append(receipt['gasUsed'])
	totGas += receipt['gasUsed']

for idx, principalAddr in enumerate(addressesOfEligiblesBuyer):
	# Registra buyer a RecSys
	#d.addSimpleMember(RN['buyer'], SMExpression(principalAddr), 100, {'from': PR['RecSys']})
	contract.functions.addSimpleMember(RN['buyer'],principalAddr,100).call({'from': PR['RecSys']})
	txHash = contract.functions.addSimpleMember(RN['buyer'],principalAddr,100).transact({'from': PR['RecSys']})
	receipt=w3.eth.waitForTransactionReceipt(txHash)
	print("SimpleMember mined:")
	pprint(dict(receipt))
	operations['simpleMember'].append(receipt['gasUsed'])
	totGas += receipt['gasUsed']

for uniAddr in addressesOfUniversities:
	# StateA.university ←− Uni_X
	#d.addSimpleMember(RN['university'], SMExpression(uniAddr), 100, {'from': PR['StateA']})
	contract.functions.addSimpleMember(RN['university'], uniAddr, 100).call({'from': PR['StateA']})
	txHash = contract.functions.addSimpleMember(RN['university'], uniAddr, 100).transact({'from': PR['StateA']})
	receipt=w3.eth.waitForTransactionReceipt(txHash)
	print("SimpleMember mined:")
	pprint(dict(receipt))
	operations['simpleMember'].append(receipt['gasUsed'])
	totGas += receipt['gasUsed']
# RecSys.university ←− StateA.university
#d.addSimpleInclusion(RN['university'], SIExpression(PR['StateA'], RN['university']), 100, {'from': PR['RecSys']})
contract.functions.addSimpleInclusion(RN['university'], PR['StateA'], RN['university'], 100).call({'from': PR['RecSys']})
txHash=contract.functions.addSimpleInclusion(RN['university'], PR['StateA'], RN['university'], 100).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("SimpleInclusion mined:")
pprint(dict(receipt))
operations['simpleInclusion'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']
# RecSys.expert ←− RecSys.university.professor
#d.addLinkedInclusion(RN['expert'], LIExpression(PR['RecSys'], RN['university'], RN['professor']), 100, {'from': PR['RecSys']})
contract.functions.addLinkedInclusion(RN['expert'],PR['RecSys'], RN['university'], RN['professor'], 100).call({'from': PR['RecSys']})
txHash=contract.functions.addLinkedInclusion(RN['expert'],PR['RecSys'], RN['university'], RN['professor'], 100).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("LinkedInclusion mined:")
pprint(dict(receipt))
operations['linkedInclusion'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']
# RecSys.reviewer ←− RecSys.expert e RecSys.buyer
#d.addIntersectionInclusion(RN['reviewer'], IIExpression(PR['RecSys'], RN['expert'], PR['RecSys'], RN['buyer']), 50, {'from': PR['RecSys']})
contract.functions.addIntersectionInclusion(RN['reviewer'],PR['RecSys'], RN['expert'], PR['RecSys'], RN['buyer'], 100).call({'from': PR['RecSys']})
txHash=contract.functions.addIntersectionInclusion(RN['reviewer'],PR['RecSys'], RN['expert'], PR['RecSys'], RN['buyer'], 100).transact({'from': PR['RecSys']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("Intersection mined:")
pprint(dict(receipt))
operations['intersectionInclusion'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']
# Alice.recommendationFrom ←− RecSys.expert
#d.addSimpleInclusion(RN['recommendationFrom'], SIExpression(PR['RecSys'], RN['expert']), 100, {'from': PR['Alice']})
contract.functions.addSimpleInclusion(RN['recommendationFrom'],PR['RecSys'], RN['expert'], 100).call({'from': PR['Alice']})
txHash=contract.functions.addSimpleInclusion(RN['recommendationFrom'],PR['RecSys'], RN['expert'], 100).transact({'from': PR['Alice']})
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("SimpleInclusion mined:")
pprint(dict(receipt))
operations['simpleInclusion'].append(receipt['gasUsed'])
totGas+=receipt['gasUsed']

print("Done")

filename = "testScenarioCn"+str(nEligibles)+"uni"+str(nUniversities)+".csv"
with open(filename,'w') as fop:
    writer=csv.writer(fop,delimiter=' ', lineterminator='\n')
    for key, vals in operations.items():
        row = []
        row.append(key)
        row.extend(vals)
        writer.writerow(row)

# -----------------------------------------------------

filename = "testScenarioSUMCn"+str(nEligibles)+".csv"
if os.path.exists(filename):
    append_write = 'a' # append if already exists
else:
    append_write = 'w' # make a new file if not
with open(filename,append_write) as fsum:
    writer=csv.writer(fsum,delimiter=' ', lineterminator='\n')
    writer.writerow([nUniversities,totGas])

# Effettua una ricerca locale di tutti i membri a cui risulta assegnato il ruolo EPapers.canAccess
print("\nSearching... ", end='')
verifGas=contract.functions.search(PR['Alice'], RN['recommendationFrom']).estimateGas()
txHash=contract.functions.search(PR['Alice'], RN['recommendationFrom']).transact({'from': PR['Alice']})
print(f'On-chain backwardSearch gas: {verifGas}')
receipt=w3.eth.waitForTransactionReceipt(txHash)
print("backwardSearch mined:")
pprint(dict(receipt))

filename = "testDartBSCn"+str(nEligibles)+".csv"
if os.path.exists(filename):
    append_write = 'a' # append if already exists
else:
    append_write = 'w' # make a new file if not
with open(filename,append_write) as f:
    writer=csv.writer(f,delimiter=' ', lineterminator='\n')
    writer.writerow([receipt['gasUsed']])

solCount = contract.functions.getRoleSolutionsCount(0,PR['Alice'], RN['recommendationFrom']).call()
print(f'Solution count: {solCount}')
proofIndex=0
for i in range(solCount) :
	currSol = contract.functions.getRoleSolution(proofIndex,PR['Alice'], RN['recommendationFrom'], i).call()
	print("Member #",i,": ", currSol[0] ,"\t",currSol[1])
