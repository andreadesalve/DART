pragma solidity >=0.6.5 <0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/dataStructures/WLinkedInclusionSet.sol";

contract TestLinkedInclusionSet {

	using WLinkedInclusionSet for WLinkedInclusionSet.Set;

    WLinkedInclusionSet.Set set;

    address constant addrA = 0xa75Ed77F5681232fEA9C71b240Bdf171E426Ca05;
    address constant addrB = 0x01Ed94bc7EC3c580848299B2BE0999Bfd3A8f996;

    bytes2 constant roleA = 0x0000;
    bytes2 constant roleB = 0xcafe;
    bytes2 constant roleC = 0xc001;
    bytes2 constant roleD = 0xf00d;

    byte constant weightA = 0xaa;
    byte constant weightB = 0xbb;
    byte constant weightC = 0xcc;
    byte constant weightD = 0xdd;
    byte constant weightE = 0xee;
    byte constant weightF = 0xff;

    // Inserting new or existing elements

    function testInsert1() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleA, roleA, weightA);
        Assert.equal(b, true, "Should successfully insert addrA.roleA.roleA with weightA");
        Assert.equal(i, 0, "Should insert addrA.roleA.roleA at index 0");
        Assert.equal(set.count(), 1, "Should contain 1 linked inclusion");
    }

    function testInsert2() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrB, roleA, roleA, weightB);
        Assert.equal(b, true, "Should successfully insert addrB.roleA.roleA with weightB");
        Assert.equal(i, 1, "Should insert addrB.roleA.roleA at index 1");
        Assert.equal(set.count(), 2, "Should contain 2 linked inclusions");
    }

    function testInsert3() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleA, roleB, weightC);
        Assert.equal(b, true, "Should successfully insert addrA.roleA.roleB with weightC");
        Assert.equal(i, 2, "Should insert addrA.roleA.roleB at index 2");
        Assert.equal(set.count(), 3, "Should contain 3 linked inclusions");
    }

    function testInsert4() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleB, roleA, weightD);
        Assert.equal(b, true, "Should successfully insert addrA.roleB.roleA with weightD");
        Assert.equal(i, 3, "Should insert addrA.roleB.roleA at index 3");
        Assert.equal(set.count(), 4, "Should contain 4 linked inclusions");
    }
    
    function testInsert5() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrB, roleC, roleD, weightE);
        Assert.equal(b, true, "Should successfully insert addrB.roleC.roleD with weightE");
        Assert.equal(i, 4, "Should insert addrB.roleC.roleD at index 4");
        Assert.equal(set.count(), 5, "Should contain 5 linked inclusions");
    }

    function testInsert6() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleC, roleD, weightF);
        Assert.equal(b, true, "Should successfully insert addrA.roleC.roleD with weightF");
        Assert.equal(i, 5, "Should insert addrA.roleC.roleD at index 5");
        Assert.equal(set.count(), 6, "Should contain 6 linked inclusions");
    }

    function testInsert7() public {
        bool b;

        (b,) = set.insert(addrA, roleB, roleA, weightA);
        Assert.equal(b, false, "Shouldn't add existing linked inclusion");
        Assert.equal(set.count(), 6, "Shouldn't count duplicate linked inclusions");
    }

    // Check for existence
    function testExistence() public {
        Assert.equal(set.exists(addrA, roleA, roleA), true, "addrA.roleA.roleA should exists");
        Assert.equal(set.exists(addrB, roleC, roleD), true, "addrB.roleC.roleD should exists");
        Assert.equal(set.exists(addrA, roleD, roleC), false, "addrA.roleD.roleC shouldn't exists");
        Assert.equal(set.exists(addrB, roleA, roleB), false, "addrB.roleA.roleB shouldn't exists");
        Assert.equal(set.exists(addrB, roleB, roleA), false, "addrB.roleB.roleA shouldn't exists");
    }

    function testGetter() public {
        address a;
        bytes2 r1;
        bytes2 r2;
        byte w;

        (a, r1, r2, w) = set.get(0);
        if(a != addrA || r1 != roleA || r2 != roleA || w != weightA)
            Assert.fail("Should contain addrA.roleA.roleA with weightA at index 0");

        (a, r1, r2, w) = set.get(2);
        if(a != addrA || r1 != roleA || r2 != roleB || w != weightC)
            Assert.fail("Should contain addrA.roleA.roleB with weightC at index 2");

        (a, r1, r2, w) = set.get(5);
        if(a != addrA || r1 != roleC || r2 != roleD || w != weightF)
            Assert.fail("Should contain addrA.roleC.roleD with weightF at index 5");
    }

    // Remove elements
    function testRemoval1() public {
        set.remove(addrA, roleA, roleA);
        set.remove(addrB, roleC, roleD);
        set.remove(addrA, roleA, roleB);

        Assert.equal(set.count(), 3, "Should contain 3 linked inclusions after removal operations");
    }

    function testRemoval2() public {
        address a;
        bytes2 r1;
        bytes2 r2;
        byte w;

        (a, r1, r2, w) = set.get(0);
        if(a != addrA || r1 != roleC || r2 != roleD || w != weightF)
            Assert.fail("Should contain addrA.roleC.roleD with weightF at index 0 after removal operations");

        (a, r1, r2, w) = set.get(1);
        if(a != addrB || r1 != roleA || r2 != roleA || w != weightB)
            Assert.fail("Should contain addrB.roleA.roleA with weightF at index 1 after removal operations");

        (a, r1, r2, w) = set.get(2);
        if(a != addrA || r1 != roleB || r2 != roleA || w != weightD)
            Assert.fail("Should contain addrA.roleB.roleA with weightD at index 2 after removal operations");
    }

    function testRemoval3() public {
        bool b;
        uint i;
        byte w;

        (b, i) = set.insert(addrA, roleA, roleA, weightF);
        Assert.equal(b, true, "Should successfully insert previously removed addrA.roleA.roleA");
        Assert.equal(i, 3, "Should reinsert addrA.roleA.roleA at index 3");

        (,,,w) = set.get(3);
        if(w != weightF) Assert.fail("Previously removed addrA.roleA.roleA should now have a different weight");
    }
}