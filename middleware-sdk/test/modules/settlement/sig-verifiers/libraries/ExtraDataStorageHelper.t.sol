// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {ExtraDataStorageHelper} from
    "src/contracts/modules/settlement/sig-verifiers/libraries/ExtraDataStorageHelper.sol";

contract ExtraDataStorageHelperTest is Test {
    function _randomNameHash(
        string memory seed
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(seed));
    }

    function test_BaseKey() public {
        uint32 vt = 1;
        bytes32 nameHash = _randomNameHash("alice");

        bytes32 expected = keccak256(abi.encode(ExtraDataStorageHelper.GLOBAL_KEY_PREFIX_HASH, vt, nameHash));
        bytes32 produced = ExtraDataStorageHelper.getKey(vt, nameHash);

        assertEq(produced, expected, "base key mismatch");
    }

    function test_TaggedKey() public {
        uint32 vt = 42;
        uint8 keyTag = 3;
        bytes32 nameHash = _randomNameHash("bob");

        bytes32 expected = keccak256(
            abi.encode(
                ExtraDataStorageHelper.GLOBAL_KEY_PREFIX_HASH,
                vt,
                ExtraDataStorageHelper.KEY_TAG_PREFIX_HASH,
                keyTag,
                nameHash
            )
        );

        bytes32 produced = ExtraDataStorageHelper.getKey(vt, keyTag, nameHash);
        assertEq(produced, expected, "tagged key mismatch");

        bytes32 untagged = ExtraDataStorageHelper.getKey(vt, nameHash);
        assertTrue(untagged != produced, "tag should alter key");
    }

    function test_IndexedKey() public {
        uint32 vt = 7;
        uint8 keyTag = 15;
        bytes32 nameHash = _randomNameHash("charlie");

        bytes32 base = ExtraDataStorageHelper.getKey(vt, keyTag, nameHash);

        // Check first few indices
        for (uint256 i = 0; i < 5; ++i) {
            bytes32 idxKey = ExtraDataStorageHelper.getKey(vt, keyTag, nameHash, i);
            bytes32 expected = bytes32(uint256(base) + i);

            assertEq(idxKey, expected, "indexed key mismatch");
            if (i > 0) {
                assertTrue(idxKey != base, "index should modify key");
            }
        }
    }

    function testFuzz_Uniqueness(
        uint32 vtA,
        uint32 vtB,
        uint8 tagA,
        uint8 tagB,
        bytes32 nameA,
        bytes32 nameB,
        uint256 idxA,
        uint256 idxB
    ) public {
        idxA = bound(idxA, 0, 1e18);
        idxB = bound(idxB, 0, 1e18);

        if (vtA == vtB && tagA == tagB && nameA == nameB && idxA == idxB) return;

        bytes32 kA = ExtraDataStorageHelper.getKey(vtA, tagA, nameA, idxA);
        bytes32 kB = ExtraDataStorageHelper.getKey(vtB, tagB, nameB, idxB);

        assertTrue(kA != kB, "distinct parameters must yield distinct keys");
    }
}
