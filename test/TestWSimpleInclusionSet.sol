pragma solidity >=0.6.5 <0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/dataStructures/WSimpleInclusionSet.sol";

contract TestSimpleInclusionSet {

	using WSimpleInclusionSet for WSimpleInclusionSet.Set;

    WSimpleInclusionSet.Set set;

    address constant addrA = 0xa75Ed77F5681232fEA9C71b240Bdf171E426Ca05;
    address constant addrB = 0x01Ed94bc7EC3c580848299B2BE0999Bfd3A8f996;
    address constant addrC = 0xE72ff44EDbB4995fB9452BFD512a2c86fe0e7f78;

    bytes2 constant roleA = 0x0000;
    bytes2 constant roleB = 0x5555;
    bytes2 constant roleC = 0xffff;

    uint8 constant weightA = 0xff;
    uint8 constant weightB = 0x00;
    uint8 constant weightC = 0x50;

    // Inserting new or existing elements

    function testInsert1() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleA, weightA);
        Assert.equal(b, true, "Should successfully insert addrA.roleA");
        Assert.equal(i, 0, "Should insert addrA.roleA at index 0");
        Assert.equal(set.count(), 1, "Should contain 1 simple inclusion");
    }

    function testInsert2() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleB, weightB);
        Assert.equal(b, true, "Should successfully insert addrA.roleB");
        Assert.equal(i, 1, "Should insert addrA.roleB at index 1");
        Assert.equal(set.count(), 2, "Should contain 2 simple inclusions");
    }

    function testInsert3() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrA, roleC, weightC);
        Assert.equal(b, true, "Should successfully insert addrA.roleC");
        Assert.equal(i, 2, "Should insert addrA.roleC at index 2");
        Assert.equal(set.count(), 3, "Should contain 3 simple inclusions");
    }

    function testInsert4() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrB, roleB, weightA);
        Assert.equal(b, true, "Should successfully insert addrB.roleB");
        Assert.equal(i, 3, "Should insert addrB.roleB at index 3");
        Assert.equal(set.count(), 4, "Should contain 4 simple inclusions");
    }
    
    function testInsert5() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrB, roleC, weightB);
        Assert.equal(b, true, "Should successfully insert addrB.roleC");
        Assert.equal(i, 4, "Should insert addrB.roleC at index 4");
        Assert.equal(set.count(), 5, "Should contain 5 simple inclusions");
    }

    function testInsert6() public {
        bool b;
        uint i;

        (b, i) = set.insert(addrC, roleC, weightC);
        Assert.equal(b, true, "Should successfully insert addrC.roleC");
        Assert.equal(i, 5, "Should insert addrC.roleC at index 5");
        Assert.equal(set.count(), 6, "Should contain 6 simple inclusions");
    }

    function testInsert7() public {
        bool b;

        (b,) = set.insert(addrA, roleB, weightC);
        Assert.equal(b, false, "Shouldn't add existing simple inclusion");
        Assert.equal(set.count(), 6, "Shouldn't count duplicate simple inclusions");
    }

    // Check for existence
    function testExistence() public {
        Assert.equal(set.exists(addrA, roleB), true, "addrA.roleB should exists");
        Assert.equal(set.exists(addrB, roleC), true, "addrB.roleC should exists");
        Assert.equal(set.exists(addrC, roleA), false, "addrC.roleA shouldn't exists");
    }

    function testGetter() public {
        address a;
        bytes2 r;
        uint8 w;

        (a, r, w) = set.get(0);
        if(a != addrA || r != roleA || w != weightA)
            Assert.fail("Should contain addrA.roleA with weightA at index 0");

        (a, r, w) = set.get(2);
        if(a != addrA || r != roleC || w != weightC)
            Assert.fail("Should contain addrA.roleC with weightC at index 2");

        (a, r, w) = set.get(5);
        if(a != addrC || r != roleC || w != weightC)
            Assert.fail("Should contain addrC.roleC with weightC at index 5");
    }

    // Remove elements
    function testRemoval1() public {
        set.remove(addrA, roleB);
        set.remove(addrB, roleC);
        set.remove(addrA, roleA);

        Assert.equal(set.count(), 3, "Should contain 3 simple inclusions after removal operations");
    }

    function testRemoval2() public {
        address a;
        bytes2 r;
        uint8 w;

        (a, r, w) = set.get(0);
        if(a != addrB || r != roleB || w != weightA)
            Assert.fail("Should contain addrB.roleB with weightA at index 0 after removal operations");

        (a, r, w) = set.get(1);
        if(a != addrC || r != roleC || w != weightC)
            Assert.fail("Should contain addrC.roleC with weightC at index 1 after removal operations");

        (a, r, w) = set.get(2);
        if(a != addrA || r != roleC || w != weightC)
            Assert.fail("Should contain addrA.roleC with weightC at index 2 after removal operations");
    }

    function testRemoval3() public {
        bool b;
        uint i;
        uint8 w;

        (b, i) = set.insert(addrA, roleA, weightB);
        Assert.equal(b, true, "Should successfully insert previously removed addrA.roleA");
        Assert.equal(i, 3, "Should reinsert addrA.roleA with weightB at index 3");

        (,,w) = set.get(3);
        if(w != weightB) Assert.fail("Previously removed addrA.roleA should now have a different weight");

    }
}