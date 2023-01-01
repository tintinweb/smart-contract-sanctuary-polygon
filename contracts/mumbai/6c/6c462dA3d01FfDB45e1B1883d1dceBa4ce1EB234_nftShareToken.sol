/**
 *Submitted for verification at polygonscan.com on 2022-12-31
*/

// SPDX-License-Identifier: MIT

// File: nft/IUniswapV2Pair.sol


pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
}

// File: nft/IERC721.sol


pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}
// File: nft/nftShareToken.sol


pragma solidity ^0.8.0;



contract nftShareToken {

    string public name = "NFT-Token";
    string public symbol = "NFTT";
    uint8 public constant decimals = 6;
    uint public totalSupply = 10**12;
    uint public finalNftPricePerShare;

    address public nftAddress;
    address public pairContractAddress;
    uint public nftId;


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) isBlacked;

    // constructor(address owner,address _pairContractAddress,address _nftAddress,uint _nftId) {
    constructor(address owner,address _nftAddress,uint _nftId) {
        _owner = owner;
        nftAddress = _nftAddress;
        // pairContractAddress = _pairContractAddress;
        nftId = _nftId;
        balances[msg.sender] = totalSupply;

        IERC721 nftContract = IERC721(_nftAddress);
        name = string.concat("NFT-Token-",nftContract.name());
        symbol = string.concat("NFTT-",nftContract.symbol());
    }

    function setPairContractAddress(address _pairContractAddress) public onlyOwner{
        pairContractAddress = _pairContractAddress;
    }  

    bool public isFinished = false;
    uint finalPricePer10pow6Token;

    function setNftIsFinished(bool _status) public onlyOwner{
        isFinished = _status;
    }
    function getFinalNftEthPrice() public view returns(uint){
        IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(pairContractAddress); 
        (uint112 _reserve0,uint112  _reserve1,uint32  _blockTimestampLast)  = uniswapV2Pair.getReserves();
        address token0 = uniswapV2Pair.token0();
        if(token0==address(this))
            return (totalSupply*_reserve1)/_reserve0;
        else
            // token0=WETH
            return (totalSupply*_reserve0)/_reserve1;
    }
    function redeemNft() public payable{
        require(!isFinished,"Nft is not available anymore.");
        uint nftTotalPrice = getFinalNftEthPrice();
        require(msg.value>=nftTotalPrice,"You need to pay for all shares.");
        
        IERC721 nftContract = IERC721(nftAddress);
        nftContract.transferFrom(address(this),msg.sender,nftId);
        finalNftPricePerShare = nftTotalPrice/totalSupply;
    }
    function redeemShare() public payable{
        require(isFinished,"Token Period Is not Finished.Use swap to exchange.");

        //get user tokens
        burn(balances[msg.sender]);

        uint balance = balanceOf(msg.sender);
        uint amount = finalNftPricePerShare * balance;

        //send eth amount based on price
        address payable receiver = payable(msg.sender);
        receiver.transfer(amount);
        
    }


    address _owner;
    function setOwner(address _newOwner) public onlyOwner{
        _owner=_newOwner;
    }
    function getOwner() public view returns(address) {
        return _owner;
    }

    function setBlackList(address _address,bool _status) public onlyOwner{
        isBlacked[_address]=_status;
    }

    function isBlackListed(address _address) public view returns (bool) {
        return isBlacked[_address];
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transfer(address receiver,uint256 numTokens) public returns (bool) {
        require(!isBlacked[msg.sender]);
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(!isBlacked[owner],"Owner is blocked");
        require(numTokens <= balances[owner],"insufficient balance");
        require(numTokens <= allowed[owner][msg.sender],"insufficient alloance");
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function burn(uint _amount) public {
        require(msg.sender==_owner,"Only owner");

        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
    }

    // ################ ecs transfer fee ##################
    uint fee; //from 0 to 1000
    function setFee(uint _fee) public onlyOwner{
        fee = _fee;
    }
    function getFee() public view returns(uint){
        return fee;
    }
    // ################ ecs transfer fee ##################


    modifier onlyOwner{
        require(msg.sender==_owner,"Only owner");
        _;
    }

    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}