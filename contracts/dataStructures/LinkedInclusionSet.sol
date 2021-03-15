pragma solidity >=0.6.5 <0.7;

library LinkedInclusionSet {

    struct Set {
        mapping(bytes24 => uint) keyPointers;
        bytes24[] keyList;
    }

    function pack(address principal, bytes2 firstRolename, bytes2 secondRolename)
            internal pure returns(bytes24 result) {

        bytes memory packed = abi.encodePacked(principal, firstRolename, secondRolename);
        assembly {
            result := mload(add(packed, 32))
        }
    }

    function insert(Set storage self, address principal, bytes2 firstRolename, bytes2 secondRolename)
            internal returns(bool, uint) {

        bytes24 key = pack(principal, firstRolename, secondRolename);
        uint pointer = self.keyPointers[key];
        if(pointer != 0) return(false, pointer - 1);

        self.keyList.push(key);
        pointer = count(self);
        self.keyPointers[key] = pointer;
        return (true, pointer - 1);
    }

    function remove(Set storage self, address principal, bytes2 firstRolename, bytes2 secondRolename) internal {
        bytes24 keyToRemove = pack(principal, firstRolename, secondRolename);
        uint pointerToRemove = self.keyPointers[keyToRemove];
        require(pointerToRemove != 0, "key not found");
        uint lastPointer = count(self);

        if(pointerToRemove != lastPointer) {
            bytes24 keyToMove = self.keyList[lastPointer - 1];
            self.keyPointers[keyToMove] = pointerToRemove;
            self.keyList[pointerToRemove - 1] = keyToMove;
        }
        self.keyList.pop();
        self.keyPointers[keyToRemove] = 0;
    }

    function count(Set storage self) internal view returns(uint) {
        return self.keyList.length;
    }

    function exists(Set storage self, address principal, bytes2 firstRolename, bytes2 secondRolename) internal view returns(bool) {
        uint pointer = self.keyPointers[pack(principal, firstRolename, secondRolename)];
        return pointer != 0;
    }

    function get(Set storage self, uint index) internal view returns(address, bytes2, bytes2) {
        bytes24 value = self.keyList[index];
        return (address(bytes20(value)), bytes2(value << 160), bytes2(value << 176));
    }

}