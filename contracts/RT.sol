pragma solidity >=0.6.5 <0.7;

import "./dataStructures/MemberSet.sol";
import "./dataStructures/SimpleInclusionSet.sol";
import "./dataStructures/LinkedInclusionSet.sol";
import "./dataStructures/IntersectionInclusionSet.sol";

import "./dataStructures/WMemberSet.sol";
import "./dataStructures/WSimpleInclusionSet.sol";
import "./dataStructures/WLinkedInclusionSet.sol";
import "./dataStructures/WIntersectionInclusionSet.sol";


contract RT {

	using MemberSet for MemberSet.Set;
	using SimpleInclusionSet for SimpleInclusionSet.Set;
	using LinkedInclusionSet for LinkedInclusionSet.Set;
	using IntersectionInclusionSet for IntersectionInclusionSet.Set;

	using WMemberSet for WMemberSet.Set;
	using WSimpleInclusionSet for WSimpleInclusionSet.Set;
	using WLinkedInclusionSet for WLinkedInclusionSet.Set;
	using WIntersectionInclusionSet for WIntersectionInclusionSet.Set;

	struct Role {
		bool exists;

		WMemberSet.Set simpleMembers;
		WSimpleInclusionSet.Set simpleInclusions;
		WLinkedInclusionSet.Set linkedInclusions;
		WIntersectionInclusionSet.Set intersectionInclusions;
	}

	mapping(address => mapping(bytes2 => Role)) policies;


	// ----------------------------------------------------- //


	modifier localRoleExists(bytes2 _rolename) {
		require(policies[msg.sender][_rolename].exists, "local role does not exist");
		_;
	}

	function newRole(bytes2 _rolename) external {
		require(!policies[msg.sender][_rolename].exists, "local role already exists");
		policies[msg.sender][_rolename].exists = true;
	}

	function addSimpleMember(bytes2 _localRolename, address _member, uint8 _weight) external
			localRoleExists(_localRolename)
			returns(bool, uint) {

		return policies[msg.sender][_localRolename].simpleMembers.insert(_member, _weight);
	}

	function addSimpleInclusion(bytes2 _localRolename, address _principal, bytes2 _rolename, uint8 _weight) external
			localRoleExists(_localRolename)
			returns(bool, uint) {

		require(policies[_principal][_rolename].exists, "remote role does not exist");
		return policies[msg.sender][_localRolename].simpleInclusions.insert(_principal, _rolename, _weight);
	}

	function addLinkedInclusion(bytes2 _localRolename, address _principal, bytes2 _firstRolename, bytes2 _secondRolename, uint8 _weight) external
			localRoleExists(_localRolename)
			returns (bool, uint) {

		require(policies[_principal][_firstRolename].exists, "1st remote role does not exist");
		return policies[msg.sender][_localRolename].linkedInclusions.insert(_principal, _firstRolename, _secondRolename, _weight);
	}

	function addIntersectionInclusion(bytes2 _localRolename, address _firstPrincipal, bytes2 _firstRolename,
			address _secondPrincipal, bytes2 _secondRolename, uint8 _weight) external
			returns (bool, uint) {

		require(policies[msg.sender][_localRolename].exists, "local role does not exist"); // no modifier: stack too deep
		require(policies[_firstPrincipal][_firstRolename].exists, "1st remote role does not exist");
		require(policies[_secondPrincipal][_secondRolename].exists, "2nd remote role does not exist");
		return policies[msg.sender][_localRolename].intersectionInclusions.insert(_firstPrincipal, _firstRolename,
			_secondPrincipal, _secondRolename, _weight);
	}


	// ----------------------------------------------------- //


	function removeSimpleMember(bytes2 _localRolename, address _member) external
			localRoleExists(_localRolename) {

		policies[msg.sender][_localRolename].simpleMembers.remove(_member);
	}

	function removeSimpleInclusion(bytes2 _localRolename, address _principal, bytes2 _rolename) external
			localRoleExists(_localRolename) {

		policies[msg.sender][_localRolename].simpleInclusions.remove(_principal, _rolename);
	}

	function removeLinkedInclusion(bytes2 _localRolename, address _principal, bytes2 _firstRolename, bytes2 _secondRolename) external
			localRoleExists(_localRolename) {

		policies[msg.sender][_localRolename].linkedInclusions.remove(_principal, _firstRolename, _secondRolename);
	}

	function removeIntersectionInclusion(bytes2 _localRolename, address _firstPrincipal, bytes2 _firstRolename,
			address _secondPrincipal, bytes2 _secondRolename) external
			localRoleExists(_localRolename) {

		policies[msg.sender][_localRolename].intersectionInclusions.remove(_firstPrincipal, _firstRolename, _secondPrincipal, _secondRolename);
	}


	// ----------------------------------------------------- //


	function getSimpleMembersCount(bytes2 _localRolename) external view
			localRoleExists(_localRolename)
			returns(uint) {

		return policies[msg.sender][_localRolename].simpleMembers.count();
	}

	function getSimpleInclusionsCount(bytes2 _localRolename) external view
			localRoleExists(_localRolename)
			returns(uint) {

		return policies[msg.sender][_localRolename].simpleInclusions.count();
	}

	function getLinkedInclusionsCount(bytes2 _localRolename) external view
			localRoleExists(_localRolename)
			returns(uint) {

		return policies[msg.sender][_localRolename].linkedInclusions.count();
	}

	function getIntersectionInclusionsCount(bytes2 _localRolename) external view
			localRoleExists(_localRolename)
			returns(uint) {

		return policies[msg.sender][_localRolename].intersectionInclusions.count();
	}

	function getSimpleMember(bytes2 _localRolename, uint _index) external view
			localRoleExists(_localRolename)
			returns(address, uint8) {

		return policies[msg.sender][_localRolename].simpleMembers.get(_index);
	}

	function getSimpleInclusion(bytes2 _localRolename, uint _index) external view
			localRoleExists(_localRolename)
			returns(address, bytes2, uint8) {

		return policies[msg.sender][_localRolename].simpleInclusions.get(_index);
	}

	function getLinkedInclusion(bytes2 _localRolename, uint _index) external view
			localRoleExists(_localRolename)
			returns(address, bytes2, bytes2, uint8) {

		return policies[msg.sender][_localRolename].linkedInclusions.get(_index);
	}

	function getIntersectionInclusion(bytes2 _localRolename, uint _index) external view
			localRoleExists(_localRolename)
			returns(address, bytes2, address, bytes2, uint8) {

		return policies[msg.sender][_localRolename].intersectionInclusions.get(_index);
	}


	// ----------------------------------------------------- //

	uint8 constant N_NODETYPES = 4;
	uint constant MAX_WEIGHT = 100; // Per quanto sia uint, deve essere rappresentabile in uint8
	uint8 constant MAX_WEIGHT_BYTE = 100;

	enum NodeType {
		SIMPLE_MEMBER,
		SIMPLE_INCLUSION,
		LINKED_INCLUSION,
		INTERSECTION_INCLUSION
	}

	struct NodeRef {
		NodeType nodeType;
		uint8 weight;
		uint index;
	}

	struct WaitingIntersectionEntry {
		address member;
		uint8 weight;
		bool exists;
		bool isSolution;
	}

	struct ProofGraph {
		// Nodes
		MemberSet.Set simpleMembers;
		SimpleInclusionSet.Set simpleInclusions;
		LinkedInclusionSet.Set linkedInclusions;
		IntersectionInclusionSet.Set intersectionInclusions;

		WMemberSet.Set[][N_NODETYPES] solutions;
		mapping(address => WaitingIntersectionEntry)[] waitingIntersectionSolutions;

		// Edges
		NodeRef[][][N_NODETYPES] edges;
		uint[][] linkedEdges;

		// Queue
		mapping(uint => NodeRef) queue;
		uint first;
		uint last;
	}



	function initQueue(ProofGraph storage self) internal {
		(self.first, self.last) = (1, 0);
	}

	function enqueue(ProofGraph storage self, NodeRef memory _nodeRef) internal {
		self.last += 1;
		self.queue[self.last] = _nodeRef;
	}

	function isQueueEmpty(ProofGraph storage self) internal view returns(bool) {
		return (self.last < self.first);
	}

	function dequeue(ProofGraph storage self) internal returns(NodeRef memory nodeRef) {
		nodeRef = self.queue[self.first];
		delete self.queue[self.first];
		self.first += 1;
	}


	function addSimpleMemberNode(ProofGraph storage self, address _member) internal returns(NodeRef memory) {
		uint index;
		bool isNew;
		(isNew, index) = self.simpleMembers.insert(_member);

		NodeRef memory newNodeRef = NodeRef(NodeType.SIMPLE_MEMBER, 0, index);
		if(isNew)
			self.edges[uint(NodeType.SIMPLE_MEMBER)].push();

		return newNodeRef;
	}

	function addSimpleInclusionNode(ProofGraph storage self, address _principal, bytes2 _rolename) internal returns(NodeRef memory) {
		uint index;
		bool isNew;
		(isNew, index) = self.simpleInclusions.insert(_principal, _rolename);

		NodeRef memory newNodeRef = NodeRef(NodeType.SIMPLE_INCLUSION, 0, index);
		if(isNew) {
			self.edges[uint(NodeType.SIMPLE_INCLUSION)].push();
			self.solutions[uint(NodeType.SIMPLE_INCLUSION)].push();
			self.linkedEdges.push();
			enqueue(self, newNodeRef);
		}

		return newNodeRef;
	}

	function addLinkedInclusionNode(ProofGraph storage self, address _principal, bytes2 _firstRolename, bytes2 _secondRolename) internal
			returns(NodeRef memory) {

		uint index;
		bool isNew;
		(isNew, index) = self.linkedInclusions.insert(_principal, _firstRolename, _secondRolename);

		NodeRef memory newNodeRef = NodeRef(NodeType.LINKED_INCLUSION, 0, index);
		if(isNew) {
			self.edges[uint(NodeType.LINKED_INCLUSION)].push();
			self.solutions[uint(NodeType.LINKED_INCLUSION)].push();
			enqueue(self, newNodeRef);
		}

		return newNodeRef;
	}

	function addIntersectionInclusionNode(ProofGraph storage self, address _firstPrincipal, bytes2 _firstRolename,
			address _secondPrincipal, bytes2 _secondRolename) internal
			returns(NodeRef memory) {

		uint index;
		bool isNew;
		(isNew, index) = self.intersectionInclusions.insert(_firstPrincipal, _firstRolename, _secondPrincipal, _secondRolename);

		NodeRef memory newNodeRef = NodeRef(NodeType.INTERSECTION_INCLUSION, 0, index);
		if(isNew) {
			self.edges[uint(NodeType.INTERSECTION_INCLUSION)].push();
			self.solutions[uint(NodeType.INTERSECTION_INCLUSION)].push();
			self.waitingIntersectionSolutions.push();
			enqueue(self, newNodeRef);
		}

		return newNodeRef;
	}

	function mulWeight(uint8 a, uint8 b) internal pure returns(uint8) {
		return uint8((uint(a) * uint(b)) / MAX_WEIGHT);
	}

	function addEdge(ProofGraph storage self, NodeRef memory _fromRef, NodeRef memory _toRef) internal {
		self.edges[uint(_fromRef.nodeType)][uint(_fromRef.index)].push(_toRef);

		if(_fromRef.nodeType == NodeType.SIMPLE_MEMBER) {
			addSolution(self, _toRef, self.simpleMembers.get(_fromRef.index), _toRef.weight);
		}
		else {
			WMemberSet.Set storage fromSolutions = self.solutions[uint(_fromRef.nodeType)][_fromRef.index];
			address currSolution;
			uint8 currWeight;

			for(uint i = 0; i < fromSolutions.count(); i++) {
				(currSolution, currWeight) = fromSolutions.get(i);
				addSolution(self, _toRef, currSolution, mulWeight(currWeight, _toRef.weight));
			}
		}
	}

	function addLinkedEdge(ProofGraph storage self, NodeRef memory fromRef, NodeRef memory toRef) internal {
		self.linkedEdges[fromRef.index].push(toRef.index);

		WMemberSet.Set storage fromSolutions = self.solutions[uint(NodeType.SIMPLE_INCLUSION)][fromRef.index];
		address currSolution;
		bytes2 roleB;
		uint8 currWeight;
		(,,roleB) = self.linkedInclusions.get(toRef.index);

		for(uint i = 0; i < fromSolutions.count(); i++) {
			(currSolution, currWeight) = fromSolutions.get(i);
			if(policies[currSolution][roleB].exists)
				addEdge(self, addSimpleInclusionNode(self, currSolution, roleB), NodeRef(NodeType.LINKED_INCLUSION, currWeight, toRef.index));
		}
	}

	function addSolution(ProofGraph storage self, NodeRef memory _nodeRef, address _solution, uint8 _weight) internal {
		bool isNew;
		uint8 weight = _weight;

		if(_nodeRef.nodeType == NodeType.INTERSECTION_INCLUSION) {
			WaitingIntersectionEntry storage waitingSolution = self.waitingIntersectionSolutions[_nodeRef.index][_solution];

			if(waitingSolution.exists) {

				if(!waitingSolution.isSolution && waitingSolution.weight > weight) {
					weight = waitingSolution.weight;
					waitingSolution.isSolution = true;
				}

				(isNew,) = self.solutions[uint(NodeType.INTERSECTION_INCLUSION)][uint(_nodeRef.index)].insert(_solution, weight);
			}
			else {
				waitingSolution.exists = true;
				waitingSolution.member = _solution;
				waitingSolution.weight = weight;
			}

		}
		else {
			(isNew,) = self.solutions[uint(_nodeRef.nodeType)][_nodeRef.index].insert(_solution, weight);
		}

		if(isNew) {
			NodeRef[] storage connectedNodes = self.edges[uint(_nodeRef.nodeType)][_nodeRef.index];
			NodeRef storage currConnectedNode;

			for(uint i = 0; i < connectedNodes.length; i++) {
				currConnectedNode = connectedNodes[i];
				addSolution(self, currConnectedNode, _solution, mulWeight(weight, currConnectedNode.weight));
			}

			if(_nodeRef.nodeType == NodeType.SIMPLE_INCLUSION) {
				bytes2 roleB;
				uint[] storage linkedInclusionsIndices = self.linkedEdges[_nodeRef.index];

				for(uint j = 0; j < linkedInclusionsIndices.length; j++) {
					(,,roleB) = self.linkedInclusions.get(linkedInclusionsIndices[j]);
					if(policies[_solution][roleB].exists)
						addEdge(self, addSimpleInclusionNode(self, _solution, roleB), NodeRef(NodeType.LINKED_INCLUSION, weight, linkedInclusionsIndices[j]));
				}
			}
		}
	}

	// ----------------------------------------------------- //

	ProofGraph[] proofGraphs;

	function getProofSolutionCount(uint proof) public view returns(uint) {
		return proofGraphs[proof].solutions[1][0].count();
	}

	function getProofSolution(uint proof, uint index) public view returns(address, uint8 weight) {
		return proofGraphs[proof].solutions[1][0].get(index);
	}


	function backwardSearch(address principal, bytes2 rolename) external {
		require(policies[principal][rolename].exists, "role does not exists");

		ProofGraph storage pGraph = proofGraphs.push();
		initQueue(pGraph);
		addSimpleInclusionNode(pGraph, principal, rolename);
		NodeRef memory currNode;
		uint i;

		address addrA;
		address addrB;
		bytes2 roleA;
		bytes2 roleB;
		uint8 weight;

		do {
			currNode = dequeue(pGraph);

			if(currNode.nodeType == NodeType.SIMPLE_INCLUSION) {
				(addrA, roleA) = pGraph.simpleInclusions.get(currNode.index);
				Role storage includedRole = policies[addrA][roleA];

				for(i = 0; i < includedRole.intersectionInclusions.count(); i++) {
					(addrA, roleA, addrB, roleB, weight) = includedRole.intersectionInclusions.get(i);
					currNode.weight = weight;
					addEdge(pGraph, addIntersectionInclusionNode(pGraph, addrA, roleA, addrB, roleB), currNode);
				}
				for(i = 0; i < includedRole.linkedInclusions.count(); i++) {
					(addrA, roleA, roleB, weight) = includedRole.linkedInclusions.get(i);
					currNode.weight = weight;
					addEdge(pGraph, addLinkedInclusionNode(pGraph, addrA, roleA, roleB), currNode);
				}
				for(i = 0; i < includedRole.simpleInclusions.count(); i++) {
					(addrA, roleA, weight) = includedRole.simpleInclusions.get(i);
					currNode.weight = weight;
					addEdge(pGraph, addSimpleInclusionNode(pGraph, addrA, roleA), currNode);
				}
				for(i = 0; i < includedRole.simpleMembers.count(); i++) {
					(addrA, weight) = includedRole.simpleMembers.get(i);
					currNode.weight = weight;
					addEdge(pGraph, addSimpleMemberNode(pGraph, addrA), currNode);
				}
			}
			else if(currNode.nodeType == NodeType.LINKED_INCLUSION) {
				(addrA, roleA, roleB) = pGraph.linkedInclusions.get(currNode.index);
				currNode.weight = MAX_WEIGHT_BYTE;
				addLinkedEdge(pGraph, addSimpleInclusionNode(pGraph, addrA, roleA), currNode);
			}
			else if(currNode.nodeType == NodeType.INTERSECTION_INCLUSION) {
				(addrA, roleA, addrB, roleB) = pGraph.intersectionInclusions.get(currNode.index);
				currNode.weight = MAX_WEIGHT_BYTE;
				addEdge(pGraph, addSimpleInclusionNode(pGraph, addrA, roleA), currNode);
				addEdge(pGraph, addSimpleInclusionNode(pGraph, addrB, roleB), currNode);
			}

		} while(!isQueueEmpty(pGraph));
	}
}
