pragma solidity >=0.6.5 <0.7;

library WLinkedInclusionSet {

    struct Set {
        mapping(bytes24 => uint) map;
        bytes25[] list;
    }

    function packKey(address _principal, bytes2 _firstRolename, bytes2 _secondRolename)
            internal pure returns(bytes24 result) {

        bytes memory packed = abi.encodePacked(_principal, _firstRolename, _secondRolename);
        assembly {
            result := mload(add(packed, 32))
        }
    }

    function packEntry(address _principal, bytes2 _firstRolename, bytes2 _secondRolename, uint8 _weight)
            internal pure returns(bytes25 result) {

        bytes memory packed = abi.encodePacked(_principal, _firstRolename, _secondRolename, _weight);
        assembly {
            result := mload(add(packed, 32))
        }
    }

    function insert(Set storage self, address _principal, bytes2 _firstRolename, bytes2 _secondRolename, uint8 _weight)
            internal returns(bool, uint) {

        bytes25 entry = packEntry(_principal, _firstRolename, _secondRolename, _weight);
        bytes24 key = bytes24(entry);
        uint pointer = self.map[key];

        if(pointer != 0) {
			if(uint8(byte(self.list[pointer - 1] << 192)) < _weight) {
				self.list[pointer - 1] = entry;
				return (true, pointer - 1);
			}
			else
				return (false, pointer - 1);
		}

        if(pointer != 0) return(false, pointer - 1);

        self.list.push(entry);
        pointer = count(self);
        self.map[key] = pointer;
        return (true, pointer - 1);
    }

    function update(Set storage self, address _principal, bytes2 _firstRolename, bytes2 _secondRolename, uint8 _weight) internal {
		bytes25 entry = packEntry(_principal, _firstRolename, _secondRolename, _weight);
		uint pointer = self.map[bytes24(entry)];
		require(pointer != 0, "entry not found");

		self.list[pointer - 1] = entry;
	}

    function remove(Set storage self, address _principal, bytes2 _firstRolename, bytes2 _secondRolename) internal {
        bytes24 keyToRemove = packKey(_principal, _firstRolename, _secondRolename);
        uint pointerToRemove = self.map[keyToRemove];
        require(pointerToRemove != 0, "entry not found");
        uint lastPointer = count(self);

        if(pointerToRemove != lastPointer) {
            bytes25 lastEntry = self.list[lastPointer - 1];
            self.map[bytes24(lastEntry)] = pointerToRemove;
            self.list[pointerToRemove - 1] = lastEntry;
        }
        self.list.pop();
        self.map[keyToRemove] = 0;
    }

    function count(Set storage self) internal view returns(uint) {
        return self.list.length;
    }

    function exists(Set storage self, address _principal, bytes2 _firstRolename, bytes2 _secondRolename) internal view returns(bool) {
        uint pointer = self.map[packKey(_principal, _firstRolename, _secondRolename)];
        return pointer != 0;
    }

    function get(Set storage self, uint _index) internal view returns(address, bytes2, bytes2, uint8) {
        bytes25 entry = self.list[_index];
        return (address(bytes20(entry)), bytes2(entry << 160), bytes2(entry << 176), uint8(byte(entry << 192)));
    }

}