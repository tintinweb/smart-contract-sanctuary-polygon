/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool){}
    function balanceOf(address account) external view returns (uint256){}
}

contract ProofOfProvenance is ERC20 {
    // API Event
    event provenanceHash( address sender, bytes32 hash, uint256 timestamp);

    // Smart contract requirements
    address private foundation; //foundation doubles as payout wallet and owner

    // Hash validation done simply
    mapping(bytes32 => address) private _owners;
    mapping(bytes32 => uint256) private _timestamps;
    mapping(bytes32 => string) private _metadata;
    
    constructor() {
        // set the contract originator as the owner
        foundation = payable( msg.sender );
    }

    function transferOwnership( address newowner ) external {
        // USE WITH CAUTION, this can not be undone
        // set to 0 to relinquish control of the smart contract forever
        // !!don't forget to set the price to zero before doing so, or 
        //  future payments will be locked on the smart contract forever.

        // This will set both control and payout to the new wallet
        require( msg.sender == foundation , "Only the owner can do that");
        foundation = newowner;
    }

    function setProvenance( bytes32 hash ) external payable {
        // Sets this unique hash to point to a verifiable claimer, forever.
        // TXN must include the keccak hash of the original work, and the fee.

        address prevOwner = _owners[ hash ];
        require(prevOwner == address(0x0) , "Hash already claimed");

        // If the hash is available then set message sender as the new owner
        _owners[ hash ] = msg.sender;
        _timestamps[ hash ] = block.timestamp;

        // MATIC donations collected on the smart contract and can be withdrawn by the foundation wallet

        // Emit event for API detection
        emit provenanceHash( msg.sender, hash, block.timestamp);
    }

    function setMetadata( bytes32 hash, string memory _metaURL ) external {
        // Allows the verified wallet to set a custom link on the smart contract
        // This link can be to an image, a data file, the original work iteself
        // or a metadata file describing the work and the owner
        require( msg.sender == _owners[hash], "Only the original claim wallet can set");
        _metadata[ hash ] = _metaURL;
    }

    function proveProvinance( bytes32 hash ) external view returns (address){
        // Returns the wallet address of the registry
        return _owners[ hash ];
    }

    function verifyTimestamp( bytes32 hash ) external view returns (uint256){
        return _timestamps[ hash ];
    }

    function withdrawMATIC() external {
        // So the foundation can be paid
        require( msg.sender == foundation , "Only the owner can do that");

        uint256 sendAmount = address(this).balance;
        (bool success, ) = foundation.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }

    function withdrawERC20( address smartContract ) external {
        // Adds ability for the owner to extract donations made in MATIC ERC20 tokens

        // So the foundation can be paid
        require( msg.sender == foundation , "Only the owner can do that");

        ERC20 COIN = ERC20(smartContract);
        uint256 coinBalance = COIN.balanceOf(address(this));
        COIN.transfer( foundation, coinBalance);
    }

    // Fallback functions for recieving Coins
    receive() external payable {}
    fallback() external payable {}
}