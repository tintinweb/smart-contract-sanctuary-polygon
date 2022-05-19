// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

/*
 * Winkies is the ERC20 token for the Winkies platform. It is received and
 * used by early supporters.
 *
 * It should act as a standard ERC20, along with some niceties (read below).
 *
 * Accounts have the ability to sign off-chain "proofs" that can be used by other
 * accounts to do the equivalent of a `transferFrom` operation. This is mostly used
 * for granting coins to presale investors. Indeed, this avoids us having to create
 * hundreds of transactions or deploy a heavy contract just to do so. Instead, people
 * will be able to fetch their "proof of claim" and submit it against the contract to
 * retrieve their coins.
 * A proof of claim is composed of:
 * - the source and destination accounts.
 * - the amount of coins involved.
 * - a block after which it can be executed, if the proof is submitted too early it should
 *   be rejected.
 * - a nonce used to avoid replay attacks, if the nonce was already seen for the same source
 *   account the proof should be discarded.
 */
contract Winkies is ERC20Capped, Ownable {
    using ECDSA for bytes32;
    address public childChainManagerProxy;
    address deployer;

    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    constructor(address _childChainManagerProxy)
        ERC20("Winkies", "WNK")
        ERC20Capped(7500000000 * (10**18))
        Ownable()
    {
        childChainManagerProxy = _childChainManagerProxy;
        deployer = msg.sender;

        // Can't mint here, because minting in child chain smart contract's constructor not allowed
    }

    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(msg.sender == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }

    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));

        _mint(user, amount);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /*
     * @description Create the hash that needs to be signed to create a claimable proof.
     * @param from The account we will claim funds from.
     * @param to The account that will receive the funds.
     * @param amount The amount of coins we will transfer.
     * @param validity The block number after which we can use the proof.
     * @param nonce A unique value to avoid replay attacks.
     * @return The hash that needs to be signed by the from account.
     */
    function hashForClaim(
        address from,
        address to,
        uint256 amount,
        uint256 validity,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(from, to, amount, validity, nonce));
    }

    /*
     * @description Verify a proof for a claim and execute it if it is valid.
     * @param proof The result of `hashForClaim` signed by `from` to authorized
     * the transfer.
     * @param from The account we will claim funds from.
     * @param to The account that will receive the funds.
     * @param amount The amount of coins we will transfer.
     * @param validity The block number after which we can use the proof.
     * @param nonce A unique value to avoid replay attacks.
     */
    function claimOffchainGrant(
        bytes calldata proof,
        address from,
        address to,
        uint256 amount,
        uint256 validity,
        uint256 nonce
    ) external {
        require(validity <= block.number, "Winkies: too early");
        require(!nonceUsed[from][nonce], "Winkies: nonce already used");

        bytes32 hashThatShouldBeSigned = hashForClaim(
            from,
            to,
            amount,
            validity,
            nonce
        ).toEthSignedMessageHash();
        require(
            hashThatShouldBeSigned.recover(proof) == from,
            "Winkies: bad proof"
        );

        nonceUsed[from][nonce] = true;
        _transfer(from, to, amount);
    }
}