pragma solidity >=0.6.5 <0.7;

library MemberSet {

	struct Set {
		mapping(address => uint) keyPointers;
		address[] keyList;
	}

	function insert(Set storage self, address key) internal returns(bool, uint) {
		uint pointer = self.keyPointers[key];

		if(pointer != 0) return (false, pointer - 1);

		self.keyList.push(key);
		pointer = count(self);
		self.keyPointers[key] = pointer;
		return (true, pointer - 1);
	}

	function remove(Set storage self, address key) internal {
		uint pointerToRemove = self.keyPointers[key];
		require(pointerToRemove != 0, "key not found");
		uint lastPointer = count(self);

		if(pointerToRemove != lastPointer) {
			address lastValue = self.keyList[lastPointer - 1];
			self.keyList[pointerToRemove - 1] = lastValue;
			self.keyPointers[lastValue] = pointerToRemove;

		}
		self.keyList.pop();
		self.keyPointers[key] = 0;
	}

	function count(Set storage self) internal view returns(uint) {
		return self.keyList.length;
	}

	function exists(Set storage self, address key) internal view returns(bool) {
		uint pointer = self.keyPointers[key];
		return pointer != 0;
	}

	function get(Set storage self, uint index) internal view returns(address) {
		return self.keyList[index];
	}

}
