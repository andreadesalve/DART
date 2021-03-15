pragma solidity >=0.6.5 <0.7;

library IntersectionInclusionSet {

	// aPrincipal.aRolename ∩ bPrincipal.bRolename
	struct InterIncl {
		address aPrincipal;
		bytes2 aRolename;
		address bPrincipal;
		bytes2 bRolename;
	}

	struct Set {
		mapping(bytes32 => uint[]) keyPointers; // hash => pointer
		InterIncl[] keyList;
	}


	function buildOrderedIntersection(address aPrincipal, bytes2 aRolename,
			address bPrincipal, bytes2 bRolename)
			internal pure returns(InterIncl memory) {

		if(aPrincipal < bPrincipal) {
			return InterIncl(aPrincipal, aRolename, bPrincipal, bRolename);
		}
		else if(aPrincipal == bPrincipal) {
			if(aRolename < bRolename)
				return InterIncl(aPrincipal, aRolename, bPrincipal, bRolename);
			else
				return InterIncl(bPrincipal, bRolename, aPrincipal, aRolename);
		}
		else {
			return InterIncl(bPrincipal, bRolename, aPrincipal, aRolename);
		}
	}

	function search(Set storage self, address aPrincipal, bytes2 aRolename,
			address bPrincipal, bytes2 bRolename) internal view
			returns (bool found, uint pointer, uint pointerIndex, InterIncl memory ordered, bytes32 hash) {

		InterIncl memory orderedIncl = buildOrderedIntersection(aPrincipal, aRolename, bPrincipal, bRolename);
		bytes32 hashKey = keccak256(abi.encodePacked(orderedIncl.aPrincipal,
											orderedIncl.aRolename,
											orderedIncl.bPrincipal,
											orderedIncl.bRolename));
		uint[] storage pointers = self.keyPointers[hashKey];

		for(uint i = 0; i < pointers.length; i++) {
			InterIncl storage keyFound = self.keyList[pointers[i]];
			if(keyFound.aPrincipal == orderedIncl.aPrincipal &&
					keyFound.bPrincipal == orderedIncl.bPrincipal &&
					keyFound.aRolename == orderedIncl.aRolename &&
					keyFound.bRolename == orderedIncl.bRolename)
				return (true, pointers[i], i, orderedIncl, hashKey);
		}

		return (false, 0, 0, orderedIncl, hashKey);
	}

	function insert(Set storage self, address aPrincipal, bytes2 aRolename,
			address bPrincipal, bytes2 bRolename) internal returns(bool, uint) {

		bool found;
		uint pointer;
		InterIncl memory orderedIncl;
		bytes32 hash;
		(found, pointer,, orderedIncl, hash) = search(self, aPrincipal, aRolename, bPrincipal, bRolename);

		if(found) return (false, pointer);

		pointer = count(self);
		self.keyList.push(orderedIncl);
		self.keyPointers[hash].push(pointer);
		return (true, pointer);
	}

	function count(Set storage self) internal view returns(uint) {
		return self.keyList.length;
	}

	function get(Set storage self, uint index) internal view returns(address, bytes2, address, bytes2) {
		InterIncl storage intersection = self.keyList[index];
		return (intersection.aPrincipal, intersection.aRolename, intersection.bPrincipal, intersection.bRolename);
	}

	function exists(Set storage self, address aPrincipal, bytes2 aRolename,
			address bPrincipal, bytes2 bRolename) internal view returns(bool) {

		bool found;
		(found,,,,) = search(self, aPrincipal, aRolename, bPrincipal, bRolename);

		return found;
	}

	function remove(Set storage self, address aPrincipal, bytes2 aRolename,
			address bPrincipal, bytes2 bRolename) internal {

		bool found;
		uint pointerToRemove;
		uint indexOfPointerToRemove;
		bytes32 hashToRemove;
		(found, pointerToRemove, indexOfPointerToRemove,, hashToRemove) = search(self, aPrincipal, aRolename, bPrincipal, bRolename);

		require(found, "key not found");

		// Rimuovi l'elemento dalla keyList
		uint lastPointer = count(self) - 1;
		uint[] storage pointers;
		if(pointerToRemove != lastPointer) {
			InterIncl storage keyToMove = self.keyList[lastPointer];
			bytes32 hashOfKeyToMove = keccak256(abi.encodePacked(keyToMove.aPrincipal,
												keyToMove.aRolename,
												keyToMove.bPrincipal,
												keyToMove.bRolename));

			pointers = self.keyPointers[hashOfKeyToMove];
			for(uint i = 0; i < pointers.length; i++) {
				if(pointers[i] == lastPointer) {
					pointers[i] = pointerToRemove;
					break;
				}
			}

			self.keyList[pointerToRemove] = keyToMove;
		}
		self.keyList.pop();

		// Rimuovi il pointer dalla lista di trabocco
		pointers = self.keyPointers[hashToRemove];
		if(indexOfPointerToRemove != (pointers.length) - 1) {
			lastPointer = pointers[pointers.length - 1];
			pointers[indexOfPointerToRemove] = lastPointer;
		}
		pointers.pop();
	}

}
