/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

//SPDX-License-Identifier: MIT

/**

                                      @@@@@@@                @@@                
       @@@@@@@@@@@@@                 @@@  @@@              @@ @@@               
    @@@@@        @@@@@              @@@   @@@            @@@  @@@               
   @@@   @@@@     @@@@             @@@@  @@@             @@@  @@                
  @@@    @@@@     @@@@             @@@  @@@             @@@ @@                  
 @@@     @@@@   @@@@@   @@@@@@@@  @@@@ @@@   @@@@@@@ @@@@@@@@@@@@  @@@@@@@@     
 @@@  @@@@@@@@@@@@    @@@@  @@@@  @@@@@@@  @@@@   @@@  @@@@       @@@  @@@@@    
@@@@    @@@@         @@@    @@@   @@@@@    @@@  @@@@   @@@@      @@@@   @@@@@@@@
 @@@   @@@@          @@@   @@@@   @@@@     @@@@@     @@@@@@@     @@@@    @@@    
 @@@   @@@@          @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@      
  @@@@@@@@                                                             
                  

*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)


pragma solidity ^0.8.0;



abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }


    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;


interface IERC721Receiver {
 
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;



interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);


    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    function balanceOf(address owner) external view returns (uint256 balance);


    function ownerOf(uint256 tokenId) external view returns (address owner);


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;


    function approve(address to, uint256 tokenId) external;


    function setApprovalForAll(address operator, bool _approved) external;


    function getApproved(uint256 tokenId) external view returns (address operator);


    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: .deps/staking.sol


pragma solidity ^0.8.0;







interface tokenI {
        function mint(address _to, uint256 _amount) external;
    }

interface nftI {
        function walletOfOwner(address _owner) external view returns (uint256[] memory); 
    }

contract HeladoStaking is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public tokenAddress = 0x84b1C3e4cA65f2101444Be75A0da27dB6B3bC181;
    IERC20 rewardToken = IERC20(tokenAddress);
    address public erc721Contract = 0xfdef1292b9d819f88f98B8B012974cb7DeA0599c;
    IERC721 stakeableNFT = IERC721(erc721Contract);
    uint256 public rewardPerSecond = 11574074074074; //1 per day
    bool public paused = false;
    uint public multiplier = 1;


    //settings and updates//
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setToken(address _contract, uint _rPerSecond) public onlyOwner {
        rewardPerSecond = _rPerSecond;
        tokenAddress = _contract;
        rewardToken = IERC20(tokenAddress);
    }


    function setNFT(address _contract) public onlyOwner {
        erc721Contract = _contract;
        stakeableNFT = IERC721(erc721Contract);
    }

    //data//
    struct stakedNFT{
        uint id; 
        address user;
        uint since;
    }

    mapping(uint => stakedNFT) nftByID;
    mapping(address => uint[]) nftByOwner;

    //transfers and work//
    function onERC721Received(address _op, address _from, uint256 _token, bytes memory) public virtual override returns (bytes4) {
        require((msg.sender == erc721Contract),"Contract not recognised!");
        require(!paused, "the contract is paused");
        stakedNFT memory staking;

        staking.id = _token;
        staking.user = _from;
        staking.since = block.timestamp;

        nftByID[_token] = staking;
        nftByOwner[_from].push(_token);

        return this.onERC721Received.selector;
    }

    function stakeAll() public {
        uint[] memory _tokens = nftI(erc721Contract).walletOfOwner(msg.sender);
        uint _tNum = _tokens.length;
        require(stakeableNFT.isApprovedForAll(msg.sender, address(this)), "Allow your Helados to enter the FREEZERVERSE.");
        for(uint i=0; i < _tNum; i++){
            stakeableNFT.safeTransferFrom(msg.sender, address(this),_tokens[i]);
        }
        
    }

    function checkOwner(uint256 _tokenID) public view returns (address){
        return nftByID[_tokenID].user;
    }

    function checkLastUpdated(uint256 _tokenID) public view returns (uint){
        return nftByID[_tokenID].since;
    }

    function getTokensOfOwner(address _owner) public view returns ( uint [] memory){
        uint[] memory ownersTokens;
        ownersTokens = nftByOwner[_owner];      
        return ownersTokens;
    }

    function checkWork(uint256 _tokenID) public view returns (uint){
        uint timeNow = block.timestamp;
        uint timeSince = nftByID[_tokenID].since;
        uint timePassed = timeNow.sub(timeSince);
        uint tokenEarned = timePassed.mul(rewardPerSecond);
        uint mult = 1;
        uint tokenSpecialMultiplier = tokenEarned.mul(mult);
        uint tokenPublicMultiplier = tokenSpecialMultiplier.mul(multiplier);
        return tokenPublicMultiplier;
    }

    function receiveReward(uint256 _tokenID) nonReentrant public {
        uint earned = checkWork(_tokenID);
        require(nftByID[_tokenID].user == msg.sender, "Not your Helado.");
        if (rewardToken.balanceOf(address(this)) <= earned) {
           tokenI(tokenAddress).mint(address(this), (earned + 1000000000000000000));
        }
        require(rewardToken.transfer(msg.sender, earned), "Error sending ICE.");
        nftByID[_tokenID].since = block.timestamp;
    }

    function returnToken(uint256 _tokenID) public {
        require(nftByID[_tokenID].user == msg.sender, "Not your Helado.");
        receiveReward(_tokenID);
        stakedNFT storage staking = nftByID[_tokenID];
        uint256[] storage stakedNFTs = nftByOwner[msg.sender];
        uint index;
        for (index = 0; index < stakedNFTs.length; index ++){
            if (stakedNFTs[index] == _tokenID) {
                break;
            }
        }
        require(index < stakedNFTs.length, "Helado not found.");
        stakedNFTs[index] = stakedNFTs[(stakedNFTs.length - 1)];
        stakedNFTs.pop();
        staking.user = address(0);
        stakeableNFT.safeTransferFrom(address(this), msg.sender, _tokenID);
    }

    function receiveRewardAll() public {
        for (uint i = 0; i < nftByOwner[msg.sender].length; i ++){
            uint tokenID = nftByOwner[msg.sender][i];
            receiveReward(tokenID);
        }
    }

    function returnTokenAll() public {
        receiveRewardAll();
        uint256[] storage stakedNFTs = nftByOwner[msg.sender];
        while (stakedNFTs.length > 0) {
            uint index = stakedNFTs.length - 1;
            //get token id
            uint _tokenID = stakedNFTs[index]; 
            //create temp object for token
            stakedNFT storage staking = nftByID[_tokenID];
            //get rid of last entry
            stakedNFTs.pop();
            //set nft to unstaked
            staking.user = address(0);
            //return to owner
            stakeableNFT.safeTransferFrom(address(this), msg.sender, _tokenID); 
        }
    }

    function emergencyReturn(address _owner) public onlyOwner {      
        uint256[] storage stakedNFTs = nftByOwner[_owner];
        uint index;
        for (index = 0; index < stakedNFTs.length; index ++){
            uint tID = stakedNFTs[index];
            stakedNFT storage staking = nftByID[tID];
            stakedNFTs[index] = stakedNFTs[(stakedNFTs.length - 1)];
            stakedNFTs.pop();
            staking.user = address(0);
            stakeableNFT.safeTransferFrom(address(this), _owner, tID);
        }

    }



    //erc20 debug//
    receive() external payable {}

    fallback() external payable {}
    
}