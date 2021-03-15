pragma solidity >=0.6.5 <0.7;

library WIntersectionInclusionSet {

	// aPrincipal.aRolename ∩ bPrincipal.bRolename
	struct InterIncl {
		address aPrincipal;
		bytes2 aRolename;
		address bPrincipal;
		bytes2 bRolename;

		uint8 weight;
	}

	struct Set {
		mapping(bytes32 => uint[]) map; // hash => pointer chain
		InterIncl[] list;
	}


	function buildOrderedIntersection(address _aPrincipal, bytes2 _aRolename,
			address _bPrincipal, bytes2 _bRolename, uint8 _weight)
			internal pure returns(InterIncl memory) {

		if(_aPrincipal < _bPrincipal) {
			return InterIncl(_aPrincipal, _aRolename, _bPrincipal, _bRolename, _weight);
		}
		else if(_aPrincipal == _bPrincipal) {
			if(_aRolename < _bRolename)
				return InterIncl(_aPrincipal, _aRolename, _bPrincipal, _bRolename, _weight);
			else
				return InterIncl(_bPrincipal, _bRolename, _aPrincipal, _aRolename, _weight);
		}
		else {
			return InterIncl(_bPrincipal, _bRolename, _aPrincipal, _aRolename, _weight);
		}
	}

	function search(Set storage self, address _aPrincipal, bytes2 _aRolename,
			address _bPrincipal, bytes2 _bRolename) internal view
			returns (bool found, uint pointer, uint inChainIndex, InterIncl memory ordered, bytes32 hash) {

		InterIncl memory orderedIncl = buildOrderedIntersection(_aPrincipal, _aRolename, _bPrincipal, _bRolename, 0x00);
		bytes32 key = keccak256(abi.encodePacked(orderedIncl.aPrincipal,
											orderedIncl.aRolename,
											orderedIncl.bPrincipal,
											orderedIncl.bRolename));
		uint[] storage chains = self.map[key];

		for(uint i = 0; i < chains.length; i++) {
			InterIncl storage foundEntry = self.list[chains[i]];
			if(foundEntry.aPrincipal == orderedIncl.aPrincipal &&
					foundEntry.bPrincipal == orderedIncl.bPrincipal &&
					foundEntry.aRolename == orderedIncl.aRolename &&
					foundEntry.bRolename == orderedIncl.bRolename)
				return (true, chains[i], i, orderedIncl, key);
		}

		return (false, 0, 0, orderedIncl, key);
	}

	function insert(Set storage self, address _aPrincipal, bytes2 _aRolename,
			address _bPrincipal, bytes2 _bRolename, uint8 _weight) internal returns(bool, uint) {

		bool found;
		uint pointer;
		InterIncl memory orderedIncl;
		bytes32 key;
		(found, pointer,, orderedIncl, key) = search(self, _aPrincipal, _aRolename, _bPrincipal, _bRolename);

		if(found) {
			InterIncl storage entry = self.list[pointer];

			if(entry.weight < _weight) {
				entry.weight = _weight;
				return (true, pointer);
			}
			else
				return (false, pointer);
		}

		pointer = count(self);
		orderedIncl.weight = _weight;
		self.list.push(orderedIncl);
		self.map[key].push(pointer);
		return (true, pointer);
	}

	function update(Set storage self, address _aPrincipal, bytes2 _aRolename,
			address _bPrincipal, bytes2 _bRolename, uint8 _weight) internal {

		bool found;
		uint pointer;
		(found, pointer,,,) = search(self, _aPrincipal, _aRolename, _bPrincipal, _bRolename);
		require(found, "entry not found");

		self.list[pointer].weight = _weight;
	}

	function count(Set storage self) internal view returns(uint) {
		return self.list.length;
	}

	function get(Set storage self, uint _index) internal view returns(address, bytes2, address, bytes2, uint8) {
		InterIncl storage entry = self.list[_index];
		return (entry.aPrincipal, entry.aRolename, entry.bPrincipal, entry.bRolename, entry.weight);
	}

	function exists(Set storage self, address _aPrincipal, bytes2 _aRolename,
			address _bPrincipal, bytes2 _bRolename) internal view returns(bool) {

		bool found;
		(found,,,,) = search(self, _aPrincipal, _aRolename, _bPrincipal, _bRolename);

		return found;
	}

	function remove(Set storage self, address _aPrincipal, bytes2 _aRolename,
			address _bPrincipal, bytes2 _bRolename) internal {

		bool found;
		uint pointerToRemove;
		uint indexOfPointerToRemove;
		bytes32 keyToRemove;
		(found, pointerToRemove, indexOfPointerToRemove,, keyToRemove) = search(self, _aPrincipal, _aRolename, _bPrincipal, _bRolename);

		require(found, "entry not found");

		// Rimuovi l'elemento dalla keyList
		uint lastPointer = count(self) - 1;
		uint[] storage pointers;
		if(pointerToRemove != lastPointer) {
			InterIncl storage lastEntry = self.list[lastPointer];
			pointers = self.map[keccak256(abi.encodePacked(lastEntry.aPrincipal,
												lastEntry.aRolename,
												lastEntry.bPrincipal,
												lastEntry.bRolename))];
			for(uint i = 0; i < pointers.length; i++) {
				if(pointers[i] == lastPointer) {
					pointers[i] = pointerToRemove;
					break;
				}
			}

			self.list[pointerToRemove] = lastEntry;
		}
		self.list.pop();

		// Rimuovi il pointer dalla lista di trabocco
		pointers = self.map[keyToRemove];
		if(indexOfPointerToRemove != (pointers.length) - 1) {
			lastPointer = pointers[pointers.length - 1];
			pointers[indexOfPointerToRemove] = lastPointer;
		}
		pointers.pop();
	}

}
