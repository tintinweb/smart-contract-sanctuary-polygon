// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWorldID {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}

pragma solidity ^0.8.18;

import { ByteHasher } from "./helpers/ByteHasher.sol";
import { IWorldID } from "./interfaces/IWorldID.sol";


contract OTCV2 {
    using ByteHasher for bytes;
    struct Deal {
        string dealType; // bankruptcy claims, saft, safe, vesting tokens, airdrop
        string opportunityName; // i.e. FTX claim, MonkeySwap SAFT
        address seller;
        address buyer;
        address attestor; // assigned attestor. each attestor might have specializations in i.e. claims
        // attestor can be swapped by contract admin, if attestor can no longer serve the duty
        uint256 sellerDeposit; // in ETH, amount deposited by seller, which is the collateral amount
        uint256 buyerDeposit; // in ETH, amount deposited by buyer, which is the total payment amount
        //why are we handing payments in ETH instead of stablecoin? because these opportunities have 
        //high beta with the overall Ethereum market. by pricing in ETH, we remove the beta and only
        //leave the alpha
        uint256 status; // 0: available, 1: taken, 2: settled
        // deal is created, seller deposits, status = 0
        // buyer is interested, buyer deposits, status = 1
        // claim is issued off-chain, attestor verify off-chain settlement, status = 2
        uint256 expiryBlock; // if block.number > expiryBlock, can return deposits to respective depositors
        // attestor can extend deadlineBlock
    }

    Deal[] public deals;
    address public admin;
    mapping(address => bool) public worldIDVerified; // Maps an address to a boolean indicating if the world ID is verified
    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The World ID group ID (always `1`)
    uint256 internal immutable groupId;

    /// @dev The World ID Action ID
    uint256 internal immutable actionId;

    /// @dev Connection between nullifiers and address. Used to correctly unverify the past profile when re-verifying.
    mapping(uint256 => address) internal nullifierHashes;

    event OfferPosted(uint256 indexed dealId, string dealType, string opportunityName, address indexed seller, uint256 sellerDeposit, uint256 expiryBlock);
    event OfferTaken(uint256 indexed dealId, address indexed buyer, uint256 buyerDeposit);
    event TradeSettled(uint256 indexed dealId, address indexed seller, address indexed buyer, uint256 sellerDeposit, uint256 buyerDeposit);
    event AttestorSwapped(uint256 indexed dealId, address indexed newAttestor);
    event ExpiryExtended(uint256 indexed dealId, uint256 newExpiry);
    event Refunded(uint256 indexed dealId, address indexed seller, address indexed buyer, uint256 sellerDeposit, uint256 buyerDeposit);
    event IDVerified(address indexed user); // Event emitted when worldIDVerify is executed and an address is verified
    event IDUnverified(address indexed user); // Event emitted when worldIDVerify is executed and an address is unverified
    //for example, a world coin user can update the verified address later, which will first unverify previous address and then verify current address

    // @notice Sets the worldcoin verification router address and some configs
    ///  _worldId The WorldID instance that will verify the proofs
    ///  _groupId The WorldID group that contains our users (always `1`)
    ///  _actionId The WorldID Action ID for the proofs
    
    constructor() {
        worldId = IWorldID(0x719683F13Eeea7D84fCBa5d7d17Bf82e03E3d260);
        groupId = 1;
        actionId = abi.encodePacked("registeruser").hashToField();
        admin = msg.sender;
    }
    
    function worldIDVerify() external {


        worldIDVerified[msg.sender] = true;
        emit IDVerified(msg.sender);
    }

    /// @notice Verify an ETH address profile
    /// @param userAddress The address profile you want to verify
    /// @param root The root of the Merkle tree (returned by the JS SDK).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demostrates the claimer is registered with World ID (returned by the JS widget).
    function verify(
        address userAddress,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public payable {
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(userAddress).hashToField(),
            nullifierHash,
            actionId,
            proof
        );

        if (nullifierHashes[nullifierHash] != address(0)) {
            address prevUserAddress= nullifierHashes[nullifierHash];

            worldIDVerified[prevUserAddress] = false;
            emit IDVerified(prevUserAddress);
        }

        worldIDVerified[userAddress] = true;
        nullifierHashes[nullifierHash] = userAddress;

        emit IDUnverified(userAddress);
    }

    function postOffer(string memory _dealType, string memory _opportunityName, uint256 _expiryBlock, uint256 _sellerDeposit, uint256 _buyerDeposit) external payable{
        Deal memory newDeal;
        require(msg.value >= _sellerDeposit,"Not enough eth deposited from seller");
        newDeal.dealType = _dealType;
        newDeal.opportunityName = _opportunityName;
        newDeal.seller = msg.sender;
        newDeal.status = 0;
        newDeal.sellerDeposit = _sellerDeposit;
        newDeal.buyerDeposit = _buyerDeposit;//the seller sets the price of the deal
        newDeal.expiryBlock = _expiryBlock;

        deals.push(newDeal);
        emit OfferPosted(deals.length - 1, _dealType, _opportunityName, msg.sender, _sellerDeposit, _expiryBlock);

    }

    function takeOffer(uint256 _dealId) external payable {
        require(_dealId < deals.length, "Invalid deal ID");
        Deal storage currentDeal = deals[_dealId];
        require(currentDeal.status == 0, "Deal not available");
        require(msg.value >= currentDeal.buyerDeposit,"Not enough eth deposited from buyer");


        currentDeal.buyer = msg.sender;
        currentDeal.buyerDeposit = msg.value;
        currentDeal.status = 1;
        emit OfferTaken(_dealId, msg.sender, msg.value);

    }

    function settleTrade(uint256 _dealId) external {
        require(_dealId < deals.length, "Invalid deal ID");
        Deal storage currentDeal = deals[_dealId];
        require(currentDeal.status == 1, "Deal not taken");

        // Perform off-chain claim verification and settlement

        // Assuming the verification is successful
        currentDeal.status = 2;
        payable(currentDeal.seller).transfer(currentDeal.sellerDeposit);
        payable(currentDeal.buyer).transfer(currentDeal.buyerDeposit);
        emit TradeSettled(_dealId, currentDeal.seller, currentDeal.buyer, currentDeal.sellerDeposit, currentDeal.buyerDeposit);

    }

    function swapAttestor(uint256 _dealId, address _newAttestor) external {
        require(_dealId < deals.length, "Invalid deal ID");
        Deal storage currentDeal = deals[_dealId];

        // Only the contract admin can swap the attestor
        require(msg.sender == currentDeal.seller, "Only contract admin can swap the attestor");

        currentDeal.attestor = _newAttestor;
        emit AttestorSwapped(_dealId, _newAttestor);

    }

    function extendExpiry(uint256 _dealId, uint256 _newExpiry) external {
        require(_dealId < deals.length, "Invalid deal ID");
        Deal storage currentDeal = deals[_dealId];

        // Only the attestor can extend the expiry
        require(msg.sender == currentDeal.attestor, "Only the attestor can extend the expiry");

        currentDeal.expiryBlock = _newExpiry;
        emit ExpiryExtended(_dealId, _newExpiry);

    }

    function refund(uint256 _dealId) external {
        require(_dealId < deals.length, "Invalid deal ID");
        Deal storage currentDeal = deals[_dealId];

        // Check if the deal has expired
        require(block.number > currentDeal.expiryBlock, "Deal has not expired yet");

        // Reset the deal status
        currentDeal.status = 0;
        currentDeal.sellerDeposit = 0;
        currentDeal.buyerDeposit = 0;

        // Refund the deposits to respective depositors
        payable(currentDeal.seller).transfer(currentDeal.sellerDeposit);
        payable(currentDeal.buyer).transfer(currentDeal.buyerDeposit);
        emit Refunded(_dealId, currentDeal.seller, currentDeal.buyer, currentDeal.sellerDeposit, currentDeal.buyerDeposit);

    }



}