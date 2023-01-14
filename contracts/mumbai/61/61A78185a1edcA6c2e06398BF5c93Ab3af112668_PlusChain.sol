// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./GraphLib.sol";

contract PlusChain is Context, Ownable {
    using GraphLib for GraphLib.Graph;
    struct NFTData {
        bytes32 assetHash;
        bytes32 nftMetadataHash;
        GraphLib.Graph txnGraph;
    }

    mapping(bytes32 => NFTData) nfts;
    mapping(bytes32 => bytes32) assetNFTMap;

    mapping(bytes32 => string) lastRecordedTxnHash;

    uint256 public NFT_REGISTRATION_FEE = 1 * 10**16; // In WEI
    uint256 public VERIFICATION_SLOT_FEE = 1 * 10**15; // In WEI

    uint256 public VERIFICATION_SLOT_DURATION = 60; // In terms of block numbers

    mapping(address => bool) public verificationPass;
    mapping(address => uint256) public verificationSlot;

    mapping(address => bool) public authToRecordNFTTransfer;

    event NFTRegistrationFeeChange(uint256 newFee);
    event VerificationSlotFeeChange(uint256 newFee);
    event VerificationSlotDurationChange(uint256 newDuration);

    event VerificationSlotGranted(address verifier, uint256 blockNumber);
    event ApprovalForVerificationPass(address verifier, bool approved);

    event RecordNFTTransferAuthorized(address account, bool approved);

    event NFTRegistered(
        uint256 nftId,
        address contractAddress,
        bytes32 assetHash,
        bytes32 nftMetaHash,
        string mintTxnHash,
        address nftAuthorAddress
    );

    event NFTTransfersRecorded(
        uint256 nftId,
        address contractAddress,
        string startTxnHash,
        string endTxnHash
    );

    /**
        ErrorCodes:
        Pluschain101 - Asset already registered
        Pluschain102 - NFT already registered
        Pluschain103 - Registration fee not received
        Pluschain104 - NFT not registered
        Pluschain105 - Invalid input
        Pluschain106 - Fee can't be 0
        Pluschain107 - Verification slot fee not received
        Pluschain108 - Invalid verification slot or verification pass
        Pluschain109 - Duration can't be 0
        Pluschain110 - Unauthorized
        Pluschain111 - Transaction already recorded
    */

    function registerNFT(
        uint256 nftId,
        address contractAddress,
        bytes32 assetHash,
        bytes32 nftMetaHash,
        string memory mintTxnHash,
        address nftAuthorAddress
    ) external payable {
        require(
            !isAssetExists(assetHash),
            "Pluschain101: Asset already registered."
        );

        bytes32 nftMapId = getNFTMapId(nftId, contractAddress);
        NFTData storage nftData = nfts[nftMapId];

        require(
            nftData.txnGraph.nodeCount() == 0,
            "Pluschain102: NFT already registered."
        );

        require(
            msg.value >= NFT_REGISTRATION_FEE,
            "Pluschain103: Registration fee not received."
        );

        assetNFTMap[assetHash] = nftMapId;

        nftData.txnGraph.insertNode(address(0x0));
        nftData.assetHash = assetHash;
        nftData.nftMetadataHash = nftMetaHash;

        nftData.txnGraph.insertEdge(
            address(0x0),
            nftAuthorAddress,
            mintTxnHash
        );

        lastRecordedTxnHash[nftMapId] = mintTxnHash;

        emit NFTRegistered(
            nftId,
            contractAddress,
            assetHash,
            nftMetaHash,
            mintTxnHash,
            nftAuthorAddress
        );
    }

    function recordNFTTransfers(
        uint256 nftId,
        address contractAddress,
        address[] memory from,
        address[] memory to,
        string[] memory txnHash
    ) external onlyAuthorized {
        require(from.length == to.length, "Pluschain105: Invalid input.");
        require(from.length == txnHash.length, "Pluschain105: Invalid input.");

        bytes32 nftMapId = getNFTMapId(nftId, contractAddress);
        NFTData storage nftData = nfts[nftMapId];

        require(
            nftData.txnGraph.nodeCount() > 0,
            "Pluschain104: NFT not registered."
        );

        uint256 n = from.length;
        for (uint256 i = 0; i < n; i++) {
            require(
                keccak256(abi.encodePacked(txnHash[i])) !=
                    keccak256(abi.encodePacked(lastRecordedTxnHash[nftMapId])),
                "Pluschain111: Transaction already recorded."
            );
            nftData.txnGraph.insertEdge(from[i], to[i], txnHash[i]);
        }

        lastRecordedTxnHash[nftMapId] = txnHash[n - 1];
        emit NFTTransfersRecorded(
            nftId,
            contractAddress,
            txnHash[0],
            txnHash[n - 1]
        );
    }

    function authorizeToRecordNFTTransfer(address account, bool approved)
        external
        onlyOwner
    {
        authToRecordNFTTransfer[account] = approved;
        emit RecordNFTTransferAuthorized(account, approved);
    }

    function buyVerificationSlot() external payable {
        require(
            msg.value >= VERIFICATION_SLOT_FEE,
            "Pluschain107: Verification slot fee not received."
        );
        uint256 verSlot = block.number + VERIFICATION_SLOT_DURATION;
        verificationSlot[_msgSender()] = verSlot;
        emit VerificationSlotGranted(_msgSender(), verSlot);
    }

    function getAssetAndMetadataHash(uint256 nftId, address contractAddress)
        external
        view
        returns (bytes32[2] memory)
    {
        require(
            (verificationSlot[_msgSender()] >= block.number) ||
                verificationPass[_msgSender()],
            "Pluschain108: Invalid verification slot or verification pass."
        );

        bytes32 nftMapId = getNFTMapId(nftId, contractAddress);
        NFTData storage nftData = nfts[nftMapId];

        require(
            nftData.txnGraph.nodeCount() > 0,
            "Pluschain104: NFT not registered."
        );

        return [nftData.assetHash, nftData.nftMetadataHash];
    }

    function getMetatoken(
        uint256 nftId,
        address contractAddress,
        address account
    ) external view returns (bytes32) {
        require(
            (verificationSlot[_msgSender()] >= block.number) ||
                verificationPass[_msgSender()],
            "Pluschain108: Invalid verification slot or verification pass."
        );

        bytes32 nftMapId = getNFTMapId(nftId, contractAddress);
        NFTData storage nftData = nfts[nftMapId];

        require(
            nftData.txnGraph.nodeCount() > 0,
            "Pluschain104: NFT not registered."
        );

        return nftData.txnGraph.nodeMetatoken(account);
    }

    function setNFTRegistrationFee(uint256 registrationFee) external onlyOwner {
        require(registrationFee > 0, "Pluschain106: Fee can't be 0.");
        NFT_REGISTRATION_FEE = registrationFee;
        emit NFTRegistrationFeeChange(registrationFee);
    }

    function setVerificationSlotFee(uint256 verificationSlotFee)
        external
        onlyOwner
    {
        require(verificationSlotFee > 0, "Pluschain106: Fee can't be 0.");
        VERIFICATION_SLOT_FEE = verificationSlotFee;
        emit VerificationSlotFeeChange(verificationSlotFee);
    }

    function setVerificationSlotDuration(uint256 verificationSlotDuration)
        external
        onlyOwner
    {
        require(
            verificationSlotDuration > 0,
            "Pluschain109: Duration can't be 0."
        );
        VERIFICATION_SLOT_DURATION = verificationSlotDuration;
        emit VerificationSlotDurationChange(verificationSlotDuration);
    }

    function setNFTVerificationPass(address verifier, bool approved)
        external
        onlyOwner
    {
        verificationPass[verifier] = approved;
        emit ApprovalForVerificationPass(verifier, approved);
    }

    function withdraw() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getNFTMapId(uint256 nftId, address contractAddress)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(contractAddress, nftId));
    }

    function isNFTRegistered(uint256 nftId, address contractAddress)
        public
        view
        returns (bool)
    {
        bytes32 nftMapId = getNFTMapId(nftId, contractAddress);
        return nfts[nftMapId].txnGraph.nodeCount() > 0;
    }

    function getLastRecordedTxnHash(uint256 nftId, address contractAddress)
        public
        view
        returns (string memory)
    {
        bytes32 nftMapId = getNFTMapId(nftId, contractAddress);
        return lastRecordedTxnHash[nftMapId];
    }

    function isAssetExists(bytes32 key) public view returns (bool) {
        if (assetNFTMap[key] != bytes32(0x0)) {
            return true;
        }
        return false;
    }

    modifier onlyAuthorized() {
        require(
            authToRecordNFTTransfer[_msgSender()],
            "Pluschain110: Unauthorized."
        );
        _;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "./HitchensUnorderedAddressSetLib.sol";
import "./HitchensUnorderedKeySetLib.sol";
import "./HitchensUnorderedPairSetLib.sol";

// Reference - https://ethereum.stackexchange.com/a/78334

library GraphLib {
    using HitchensUnorderedKeySetLib for HitchensUnorderedKeySetLib.Set;
    using HitchensUnorderedAddressSetLib for HitchensUnorderedAddressSetLib.Set;
    using HitchensUnorderedPairSetLib for HitchensUnorderedPairSetLib.Set;

    struct EdgeStruct {
        address source;
        address target;
        HitchensUnorderedPairSetLib.Set weights;
    }

    struct NodeStruct {
        HitchensUnorderedKeySetLib.Set sourceEdgeSet; // in
        HitchensUnorderedKeySetLib.Set targetEdgeSet; // out
        bytes32 metatoken;
    }

    struct Graph {
        HitchensUnorderedAddressSetLib.Set nodeSet;
        HitchensUnorderedKeySetLib.Set edgeSet;
        mapping(address => NodeStruct) nodeStructs;
        mapping(bytes32 => EdgeStruct) edgeStructs;
    }

    function insertNode(Graph storage g, address nodeAddress) internal {
        g.nodeSet.insert(nodeAddress);
    }

    function insertEdge(
        Graph storage g,
        address sourceId,
        address targetId,
        string memory txnHash
    ) internal returns (bytes32 edgeId) {
        require(g.nodeSet.exists(sourceId), "Graph101: Unknown sourceId.");
        // require(g.nodeSet.exists(targetId), "Graph: Unknown targetId.");
        if (!g.nodeSet.exists(targetId)) {
            insertNode(g, targetId);
        }

        edgeId = keccak256(abi.encodePacked(sourceId, targetId));
        EdgeStruct storage e = g.edgeStructs[edgeId];
        NodeStruct storage t = g.nodeStructs[targetId];

        HitchensUnorderedPairSetLib.Pair memory weight = calculateNewEdgeWeight(
            g,
            sourceId,
            targetId
        );
        e.weights.insert(weight);

        if (!g.edgeSet.exists(edgeId)) {
            g.edgeSet.insert(edgeId);
            NodeStruct storage s = g.nodeStructs[sourceId];
            s.targetEdgeSet.insert(edgeId);
            t.sourceEdgeSet.insert(edgeId);
            e.source = sourceId;
            e.target = targetId;
        }

        t.metatoken = calculateMetatoken(g, sourceId, targetId, txnHash);
    }

    // View functions

    function calculateNewEdgeWeight(
        Graph storage g,
        address sourceId,
        address targetId
    ) internal view returns (HitchensUnorderedPairSetLib.Pair memory) {
        uint256 a = getSourceEdgeCount(g, sourceId);
        uint256 b = getSourceEdgeCount(g, targetId) + 1;
        return HitchensUnorderedPairSetLib.Pair(a, b);
    }

    function getSourceEdgeCount(Graph storage g, address nodeAddress)
        internal
        view
        returns (uint256 count)
    {
        HitchensUnorderedKeySetLib.Set storage edgeSet = g
            .nodeStructs[nodeAddress]
            .sourceEdgeSet;
        uint256 a = edgeSet.count();
        count = 0;
        for (uint256 i = 0; i < a; i++) {
            count += g.edgeStructs[edgeSet.keyAtIndex(i)].weights.count();
        }
        return count;
    }

    function calculateMetatoken(
        Graph storage g,
        address sourceId,
        address targetId,
        string memory txnHash
    ) internal view returns (bytes32) {
        bytes memory sourceMT = bytes(
            iToHex(abi.encodePacked(g.nodeStructs[sourceId].metatoken))
        );
        bytes memory targetMT = bytes(
            iToHex(abi.encodePacked(g.nodeStructs[targetId].metatoken))
        );
        return keccak256(string.concat(sourceMT, targetMT, bytes(txnHash)));
    }

    function iToHex(bytes memory buffer) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

    function edgeExists(Graph storage g, bytes32 edgeId)
        internal
        view
        returns (bool exists)
    {
        return (g.edgeSet.exists(edgeId));
    }

    function edgeCount(Graph storage g) internal view returns (uint256 count) {
        return g.edgeSet.count();
    }

    function edgeAtIndex(Graph storage g, uint256 index)
        internal
        view
        returns (bytes32 edgeId)
    {
        return g.edgeSet.keyAtIndex(index);
    }

    function edgeSource(Graph storage g, bytes32 edgeId)
        internal
        view
        returns (address sourceId)
    {
        require(edgeExists(g, edgeId), "Graph103: Unknown edge.");
        EdgeStruct storage e = g.edgeStructs[edgeId];
        return e.source;
    }

    function edgeTarget(Graph storage g, bytes32 edgeId)
        internal
        view
        returns (address targetId)
    {
        require(edgeExists(g, edgeId), "Graph103: Unknown edge.");
        EdgeStruct storage e = g.edgeStructs[edgeId];
        return e.target;
    }

    // Nodes

    function nodeExists(Graph storage g, address nodeAddress)
        internal
        view
        returns (bool exists)
    {
        return (g.nodeSet.exists(nodeAddress));
    }

    function nodeCount(Graph storage g) internal view returns (uint256 count) {
        return g.nodeSet.count();
    }

    function node(Graph storage g, address nodeAddress)
        internal
        view
        returns (uint256 sourceCount, uint256 targetCount)
    {
        require(g.nodeSet.exists(nodeAddress), "Graph102: Unknown node.");
        NodeStruct storage n = g.nodeStructs[nodeAddress];
        return (n.sourceEdgeSet.count(), n.targetEdgeSet.count());
    }

    function nodeSourceEdgeAtIndex(
        Graph storage g,
        address nodeAddress,
        uint256 index
    ) internal view returns (bytes32 sourceEdge) {
        require(g.nodeSet.exists(nodeAddress), "Graph102: Unknown node.");
        NodeStruct storage n = g.nodeStructs[nodeAddress];
        sourceEdge = n.sourceEdgeSet.keyAtIndex(index);
    }

    function nodeTargetEdgeAtIndex(
        Graph storage g,
        address nodeAddress,
        uint256 index
    ) internal view returns (bytes32 targetEdge) {
        require(g.nodeSet.exists(nodeAddress), "Graph102: Unknown node.");
        NodeStruct storage n = g.nodeStructs[nodeAddress];
        targetEdge = n.targetEdgeSet.keyAtIndex(index);
    }

    function nodeMetatoken(Graph storage g, address nodeAddress)
        internal
        view
        returns (bytes32)
    {
        require(g.nodeSet.exists(nodeAddress), "Graph102: Unknown node.");
        NodeStruct storage n = g.nodeStructs[nodeAddress];
        return n.metatoken;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
Hitchens UnorderedAddressSet v0.93

Library for managing CRUD operations in dynamic address sets.

https://github.com/rob-Hitchens/UnorderedKeySet

Copyright (c), 2019, Rob Hitchens, the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library HitchensUnorderedAddressSetLib {
    struct Set {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    function insert(Set storage self, address key) internal {
        require(
            !exists(self, key),
            "UnorderedAddressSet101: Address (key) already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, address key) internal {
        require(
            exists(self, key),
            "UnorderedAddressSet102: Address (key) does not exist in the set."
        );
        address keyToMove = self.keyList[count(self) - 1];
        uint256 rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    function exists(Set storage self, address key)
        internal
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint256 index)
        internal
        view
        returns (address)
    {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }

    function keys(Set storage self) public view returns (address[] memory) {
        return self.keyList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
Hitchens UnorderedKeySet v0.93

Library for managing CRUD operations in dynamic key sets.

https://github.com/rob-Hitchens/UnorderedKeySet

Copyright (c), 2019, Rob Hitchens, the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library HitchensUnorderedKeySetLib {
    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet101: Key cannot be 0x0");
        require(
            !exists(self, key),
            "UnorderedKeySet102: Key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(
            exists(self, key),
            "UnorderedKeySet103: Key does not exist in the set."
        );
        bytes32 keyToMove = self.keyList[count(self) - 1];
        uint256 rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    function exists(Set storage self, bytes32 key)
        internal
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }

    function keys(Set storage self) public view returns (bytes32[] memory) {
        return self.keyList;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
Reference:

Hitchens UnorderedKeySet v0.93

https://github.com/rob-Hitchens/UnorderedKeySet
*/

library HitchensUnorderedPairSetLib {
    struct Pair {
        uint256 a;
        uint256 b;
    }

    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        Pair[] keyList;
    }

    function insert(Set storage self, Pair memory key) internal {
        require(
            !(key.a == 0 && key.b == 0),
            "UnorderedPairSet101: Key cannot be 0,0"
        );
        require(
            !exists(self, key),
            "UnorderedPairSet102: Key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[keccak256(abi.encodePacked(key.a, key.b))] =
            self.keyList.length -
            1;
    }

    function remove(Set storage self, Pair memory key) internal {
        require(
            exists(self, key),
            "UnorderedPairSet103: Key does not exist in the set."
        );
        Pair memory keyToMove = self.keyList[count(self) - 1];

        bytes32 keyToMoveHash = keccak256(
            abi.encodePacked(keyToMove.a, keyToMove.b)
        );
        bytes32 keyHash = keccak256(abi.encodePacked(key.a, key.b));

        uint256 rowToReplace = self.keyPointers[keyHash];
        self.keyPointers[keyToMoveHash] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[keyHash];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    function exists(Set storage self, Pair memory key)
        internal
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        bytes32 keyHash = keccak256(abi.encodePacked(key.a, key.b));

        Pair storage p = self.keyList[self.keyPointers[keyHash]];
        return (p.a == key.a && p.b == key.b);
    }

    function keyAtIndex(Set storage self, uint256 index)
        internal
        view
        returns (Pair memory)
    {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }

    function keys(Set storage self) public view returns (Pair[] memory) {
        return self.keyList;
    }
}