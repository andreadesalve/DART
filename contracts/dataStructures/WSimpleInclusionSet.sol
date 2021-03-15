pragma solidity >=0.6.5 <0.7;

library WSimpleInclusionSet {

	struct Set {
		mapping(bytes22 => uint) map;
		bytes23[] list;
	}

	function packKey(address _principal, bytes2 _rolename) internal pure returns(bytes22 result) {
		bytes memory packed = abi.encodePacked(_principal, _rolename);
		assembly {
			result := mload(add(packed, 32))
		}
	}

	function packEntry(address _principal, bytes2 _rolename, uint8 _weight) internal pure returns(bytes23 result) {
		bytes memory packed = abi.encodePacked(_principal, _rolename, _weight);
		assembly {
			result := mload(add(packed, 32))
		}
	}

	function insert(Set storage self, address _principal, bytes2 _rolename, uint8 _weight) internal returns(bool, uint) {
		bytes23 entry = packEntry(_principal, _rolename, _weight);
		bytes22 key = bytes22(entry);
		uint pointer = self.map[key];

		if(pointer != 0) {
			if(uint8(byte(self.list[pointer - 1] << 176)) < _weight) {
				self.list[pointer - 1] = entry;
				return (true, pointer - 1);
			}
			else
				return (false, pointer - 1);
		}

		self.list.push(entry);
		pointer = count(self);
		self.map[key] = pointer;
		return (true, pointer - 1);
	}

	function update(Set storage self, address _principal, bytes2 _rolename, uint8 _weight) internal {
		bytes23 entry = packEntry(_principal, _rolename, _weight);
		uint pointer = self.map[bytes22(entry)];
		require(pointer != 0, "entry not found");

		self.list[pointer - 1] = entry;
	}

	function remove(Set storage self, address _principal, bytes2 _rolename) internal {
		bytes22 keyToRemove = packKey(_principal, _rolename);
		uint pointerToRemove = self.map[keyToRemove];
		require(pointerToRemove != 0, "entry not found");
		uint lastPointer = count(self);

		if(pointerToRemove != lastPointer) {
			bytes23 lastEntry = self.list[lastPointer - 1];
			self.map[bytes22(lastEntry)] = pointerToRemove;
			self.list[pointerToRemove - 1] = lastEntry;
		}
		self.list.pop();
		self.map[keyToRemove] = 0;
	}

	function count(Set storage self) internal view returns(uint) {
		return self.list.length;
	}

	function exists(Set storage self, address _principal, bytes2 _rolename) internal view returns(bool) {
		uint pointer = self.map[packKey(_principal, _rolename)];
		return pointer != 0;
	}

	function get(Set storage self, uint _index) internal view returns(address, bytes2, uint8) {
		bytes23 entry = self.list[_index];
		return (address(bytes20(entry)), bytes2(entry << 160), uint8(byte(entry << 176)));
	}

}