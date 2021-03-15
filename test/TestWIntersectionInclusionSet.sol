pragma solidity >=0.6.5 <0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/dataStructures/WIntersectionInclusionSet.sol";

contract TestIntersectionInclusionSet {

	using WIntersectionInclusionSet for WIntersectionInclusionSet.Set;

    WIntersectionInclusionSet.Set set;

    address constant addrA = 0xa75Ed77F5681232fEA9C71b240Bdf171E426Ca05;
    address constant addrB = 0x01Ed94bc7EC3c580848299B2BE0999Bfd3A8f996;
    address constant addrC = 0xE72ff44EDbB4995fB9452BFD512a2c86fe0e7f78;

    bytes2 constant roleA = 0x0000;
    bytes2 constant roleB = 0xcafe;
    bytes2 constant roleC = 0xc001;

    byte constant weightA = 0xaa;
    byte constant weightB = 0xbb;
    byte constant weightC = 0xcc;
    byte constant weightD = 0xdd;

    // Inserting new or existing elements

    function testInsert1() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleA, addrB, roleB, weightA);
        Assert.equal(b, true, "Should successfully insert addrA.roleA ∩ addrB.roleB with weightA");
        Assert.equal(i, 0, "Should insert addrA.roleA ∩ addrB.roleB at index 0");
        Assert.equal(set.count(), 1, "Should contain 1 intersection inclusion");
    }

    function testInsert2() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleA, addrA, roleA, weightB);
        Assert.equal(b, true, "Should successfully insert addrA.roleA ∩ addrA.roleA with weightB");
        Assert.equal(i, 1, "Should insert addrA.roleA ∩ addrA.roleA at index 1");
        Assert.equal(set.count(), 2, "Should contain 2 intersection inclusions");
    }

    function testInsert3() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleB, addrB, roleA, weightC);
        Assert.equal(b, true, "Should successfully insert addrA.roleB ∩ addrB.roleA with weightC");
        Assert.equal(i, 2, "Should insert addrA.roleB ∩ addrB.roleA at index 2");
        Assert.equal(set.count(), 3, "Should contain 3 intersection inclusions");
    }

    function testInsert4() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrC, roleA, addrC, roleC, weightD);
        Assert.equal(b, true, "Should successfully insert addrC.roleA ∩ addrC.roleC with weightD");
        Assert.equal(i, 3, "Should insert addrC.roleA ∩ addrC.roleC at index 3");
        Assert.equal(set.count(), 4, "Should contain 4 intersection inclusions");
    }
    
    function testInsert7() public {
        bool b;

        (b,) = set.insert(addrB, roleB, addrA, roleA, weightC);
        Assert.equal(b, false, "Shouldn't add existing intersection inclusion");

        (b,) = set.insert(addrB, roleA, addrA, roleB, weightA);
        Assert.equal(b, false, "Shouldn't add existing intersection inclusion");

        (b,) = set.insert(addrA, roleA, addrA, roleA, weightB);
        Assert.equal(b, false, "Shouldn't add existing intersection inclusion");

        Assert.equal(set.count(), 4, "Shouldn't count duplicate intersection inclusions");
    }

    // Check for existence
    function testExistence() public {
        Assert.equal(set.exists(addrB, roleB, addrA, roleA), true, "addrB.roleB ∩ addrA.roleA should exists");
        Assert.equal(set.exists(addrC, roleC, addrC, roleA), true, "addrC.roleC ∩ addrC.roleA should exists");
        Assert.equal(set.exists(addrA, roleA, addrA, roleB), false, "addrA.roleA ∩ addrA.roleB shouldn't exists");
        Assert.equal(set.exists(addrC, roleA, addrC, roleA), false, "addrC.roleA ∩ addrC.roleA shouldn't exists");
    }

    function testGetter() public {
        address a1;
        bytes2 r1;
        address a2;
        bytes2 r2;
        byte w;

        (a1, r1, a2, r2, w) = set.get(0);
        if(w != weightA || !((a1 == addrA && r1 == roleA && a2 == addrB && r2 == roleB) ||
                (a1 == addrB && r1 == roleB && a2 == addrA && r2 == roleA)))
            Assert.fail("Should contain addrA.roleA ∩ addrB.roleB with weightA at index 0");

        (a1, r1, a2, r2, w) = set.get(2);
        if(w != weightC || !((a1 == addrA && r1 == roleB && a2 == addrB && r2 == roleA) ||
                (a1 == addrB && r1 == roleA && a2 == addrA && r2 == roleB)))
            Assert.fail("Should contain addrA.roleB ∩ addrB.roleA with weightC at index 2");
    }


    // Remove elements
    function testRemoval1() public {
        set.remove(addrA, roleA, addrB, roleB);
        set.remove(addrB, roleA, addrA, roleB);

        Assert.equal(set.count(), 2, "Should contain 2 intersection inclusions after removal operations");
    }

    function testRemoval2() public {
        address a1;
        bytes2 r1;
        address a2;
        bytes2 r2;
        byte w;

        (a1, r1, a2, r2, w) = set.get(0);
        if(w != weightD || !((a1 == addrC && r1 == roleA && a2 == addrC && r2 == roleC) ||
                (a1 == addrC && r1 == roleC && a2 == addrC && r2 == roleA)))
            Assert.fail("Should contain addrC.roleA ∩ addrC.roleB with weightD at index 0");

        (a1, r1, a2, r2, w) = set.get(1);
        if((w != weightB || a1 != addrA || r1 != roleA || a2 != addrA || r2 != roleA))
            Assert.fail("Should contain addrA.roleA ∩ addrA.roleA with weightB at index 1");
    }

    function testRemoval3() public {
        bool b;
        uint i;
        byte w;

        (b, i) = set.insert(addrA, roleB, addrB, roleA, weightA);
        Assert.equal(b, true, "Should successfully insert previously removed addrA.roleB ∩ addrB.roleA");
        Assert.equal(i, 2, "Should reinsert addrA.roleB ∩ addrB.roleA at index 2");

        (,,,,w) = set.get(2);
        if(w != weightA) Assert.fail("Previously removed addrA.roleB ∩ addrB.roleA should now have a different weight");
    }
}