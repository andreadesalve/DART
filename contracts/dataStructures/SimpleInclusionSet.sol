pragma solidity >=0.6.5 <0.7;

library SimpleInclusionSet {

	struct Set {
		mapping(bytes22 => uint) keyPointers;
		bytes22[] keyList;
	}

	function pack(address principal, bytes2 rolename) internal pure returns(bytes22 result) {
		bytes memory packed = abi.encodePacked(principal, rolename);
		assembly {
			result := mload(add(packed, 32))
		}
	}

	function insert(Set storage self, address principal, bytes2 rolename) internal returns(bool, uint) {
		bytes22 key = pack(principal, rolename);
		uint pointer = self.keyPointers[key];
		if(pointer != 0) return (false, pointer - 1);

		self.keyList.push(key);
		pointer = count(self);
		self.keyPointers[key] = pointer;
		return (true, pointer - 1);
	}

	function remove(Set storage self, address principal, bytes2 rolename) internal {
		bytes22 keyToRemove = pack(principal, rolename);
		uint pointerToRemove = self.keyPointers[keyToRemove];
		require(pointerToRemove != 0, "key not found");
		uint lastPointer = count(self);

		if(pointerToRemove != lastPointer) {
			bytes22 keyToMove = self.keyList[lastPointer - 1];
			self.keyPointers[keyToMove] = pointerToRemove;
			self.keyList[pointerToRemove - 1] = keyToMove;
		}
		self.keyList.pop();
		self.keyPointers[keyToRemove] = 0;
	}

	function count(Set storage self) internal view returns(uint) {
		return self.keyList.length;
	}

	function exists(Set storage self, address principal, bytes2 rolename) internal view returns(bool) {
		uint pointer = self.keyPointers[pack(principal, rolename)];
		return pointer != 0;
	}

	function get(Set storage self, uint index) internal view returns(address, bytes2) {
		bytes22 value = self.keyList[index];
		return (address(bytes20(value)), bytes2(value << 160));
	}

}