/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;


library Address {

    function isContract(address account) internal view returns (bool) {


        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

 
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }


    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}



pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function decimals() external pure returns (uint8);
}

pragma solidity ^0.8.0;
 
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
    
}



interface IERC721 is IERC165 {

    struct NFTTraits {
        uint256 speed;
    }

   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

   
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

   
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

   
    function balanceOf(address owner) external view returns (uint256 balance);

  
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address to,uint amount,uint roundNumber) external returns (uint256);
    function tokenTraits(uint256 tokenId) external view returns (NFTTraits memory);
    function getCarName(uint256 tokenId) external view returns (string memory);

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


    function getApproved(uint256 tokenId) external view returns (address operator);

 
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }


}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract gameInfo{

    uint256 public unionFee=10000*10**6;

    struct PERIOD{
        // 回合编号
        uint256 roundNumber;
        // 回合  列表
        mapping(uint256=>Round) roundList;
        // 待定回合  列表
        uint[]  pendingRoundList;
        // 待定回合索引
        mapping(uint=>uint) pendingRoundIndex;
    }

    struct Round{
        address[] player;
        uint256 totalPlayer;
        mapping(address =>ParticipantInfo) address_participantInfo;
        uint256 startTime;
        uint256 endTime;
    }

    struct ParticipantInfo{
        uint256  roundNumber;
        uint256  tokenId;
        uint256  amount;
        uint256  speed;
        string   name;
        bool     isWinner;
        uint256  rewardUSDT;
        uint256  rewardGameToken;
        uint256  endtime;
    }

    mapping(address=>mapping(string=>uint8)) public recommendedTeamLevel;

    struct Player {
        uint256 id;
        bool  isUnion;
        uint256 totalUnionReward;
        uint256 extractedUnionReward;
        address[] directRecommendAddress;
        address referrer;
        mapping(uint=>uint[]) pendingRoundList;
        mapping(uint=>uint) pendingRoundIndex;
        uint256 totalPlayCount;
        uint256 totalReferralReward;
        uint256 extractedReferralReward;
        uint256 totalUSDTReward;
        uint256 extractedUSDTReward;
        uint256 totalGameTokenReward;
        uint256 extractedGameTokenReturn;
        ReferralReward[] referralRewardList;
        GameTokenRewardInfo[] GameTokenRewardList;
        ParticipantInfo[] playHistoryInfo;
    }
    struct TeamInfo{
        string teamLevel;
        uint256 validDirectRecommend;
        uint256 validAgentSubordinate;
        address[] agentSubordinateAddress;
        uint256 totalUSDTReward;
        uint256 extractedUSDTReward;
    }

    struct GameTokenRewardInfo {
        uint256 amount; 
        uint256 returnTime;
        uint256 returnCount;
        uint256 remainingAmount;
    }

    struct ReferralReward {
        address player; 
        uint256 returnTime;
        uint256 referralReward;
    }

    mapping(uint=>PERIOD) public periods;
    mapping(address=>Player) public playerInfo;
    mapping(address=>TeamInfo) public teamInfo;

    address[] public allAddress;
    uint256 public lastUserId=1;

    
    address public usdtAddress=0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public gameTokenAddress=0x13787D8330e81722Ef7c8845815209D636DF110B;
    address public defaultReferrerAddress=0x9C081EE76Cd4A3b090e675c4bafB0C9b05f6aCDA;

    address public nftAddress=0xEb25099BC7e4633f39bb23D828FE943ea8958E97;

    address public beneficiary1_20=0xf8d49B083F6b397E63b63dA2174f97B701C8C432;
    address public beneficiary1_56=0xB3a4678640E5661f17184685Fa846DB9E5Ecd241;
    address public beneficiary1_24=0x7C580710F21905C6e48146428170738d8df1e1f5;

}

contract ownerControl is Context,Ownable,gameInfo{
    using SafeMath for uint256;

    function setUnionFee(uint256 amount) public onlyOwner{
        unionFee=amount;
    }

    function withdrawToken(address _tokenContract)public onlyOwner{
        uint256 balance=IERC20(_tokenContract).balanceOf(address(this));
        IERC20(_tokenContract).transfer(owner(),balance);
    }
 

    function setnftAddress(address _nftAddress) public onlyOwner{
        nftAddress=_nftAddress;
    }
    function setgameTokenAddress(address _gameTokenAddress) public onlyOwner{
        gameTokenAddress=_gameTokenAddress;
 
    }
    

}
contract racingGame is ownerControl{
        
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor () {
        IERC20(usdtAddress).approve(
                address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff),
                10000000000000000000000000000000000000000000000000000
        );

        uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

        PERIOD storage newPeriod1=periods[20];
        newPeriod1.roundNumber+=1;
        newPeriod1.roundList[newPeriod1.roundNumber].startTime=block.timestamp;
        PERIOD storage newPeriod2=periods[100];
        newPeriod2.roundNumber+=1;
        newPeriod2.roundList[newPeriod2.roundNumber].startTime=block.timestamp;
        PERIOD storage newPeriod3=periods[300];
        newPeriod3.roundNumber+=1;
        newPeriod3.roundList[newPeriod3.roundNumber].startTime=block.timestamp;
        PERIOD storage newPeriod4=periods[500];
        newPeriod4.roundNumber+=1;
        newPeriod4.roundList[newPeriod4.roundNumber].startTime=block.timestamp;
        PERIOD storage newPeriod5=periods[1000];
        newPeriod5.roundNumber+=1;
        newPeriod5.roundList[newPeriod5.roundNumber].startTime=block.timestamp;

        PERIOD storage newPeriod6=periods[3000];
        newPeriod6.roundNumber+=1;
        newPeriod6.roundList[newPeriod6.roundNumber].startTime=block.timestamp;

        PERIOD storage newPeriod7=periods[50];
        newPeriod7.roundNumber+=1;
        newPeriod7.roundList[newPeriod7.roundNumber].startTime=block.timestamp;


            


        teamInfo[defaultReferrerAddress].teamLevel="zero";
        recommendedTeamLevel[address(0)]["zero"]+=1;
     }
    function isUserExists(address user) public view returns (bool) {
        return (playerInfo[user].referrer!=address(0));
    }
    function play(uint256 amount,uint256 roundNumber,bool isCreateRoom) public {
        require(!address(msg.sender).isContract(),"Address: The transferred address cannot be a contract");
        Player storage player=playerInfo[msg.sender];
        bool isExists =isUserExists(msg.sender);
        require(isExists,"you are not registered");
        require(player.GameTokenRewardList.length<200,"This address has participated more than 200 times");

        PERIOD storage periodInfo=periods[amount];

        if(isCreateRoom){
            if(periodInfo.roundList[periodInfo.roundNumber].totalPlayer!=0){
                periodInfo.roundNumber+=1;
                periodInfo.roundList[periodInfo.roundNumber].startTime=block.timestamp;
                roundNumber=periodInfo.roundNumber;
            }else{
                roundNumber=periodInfo.roundNumber;
            }
        }


        require(periodInfo.roundNumber>=roundNumber&&roundNumber!=0,"Room number does not exist");
        require(periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].amount==0,"you have been involved");
        require(periodInfo.roundList[roundNumber].totalPlayer<5,"The room is full or closed");
        periodInfo.roundList[roundNumber].player.push(msg.sender);
          IERC20(usdtAddress).transferFrom(
                address(msg.sender),
                address(this),
                amount.mul(10**6)
          );
        uint256 tokenId=IERC721(nftAddress).mint(address(this),amount,roundNumber);

        periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].tokenId=tokenId;
        periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].amount=amount.mul(10**6);
        periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].roundNumber=roundNumber;
        periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].speed=IERC721(nftAddress).tokenTraits(tokenId).speed;
        periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].name=IERC721(nftAddress).getCarName(tokenId);
        if(periodInfo.roundList[roundNumber].totalPlayer==0){
            periodInfo.pendingRoundList.push(roundNumber);
            periodInfo.pendingRoundIndex[roundNumber]=periodInfo.pendingRoundList.length-1;
        }
        periodInfo.roundList[roundNumber].totalPlayer+=1;
        player.pendingRoundList[amount].push(roundNumber);
        player.pendingRoundIndex[roundNumber]=player.pendingRoundList[amount].length-1;
        player.totalPlayCount+=1;
 

        playerInfo[player.referrer].referralRewardList.push(
            ReferralReward({player:msg.sender,referralReward:periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].amount.mul(2).div(100),returnTime:block.timestamp})
            );


        playerInfo[player.referrer].totalReferralReward=playerInfo[player.referrer].totalReferralReward.add(periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].amount.mul(2).div(100));


        dividendsToTeam(msg.sender,periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].amount.div(5).mul(10).div(100));

        dividendsToUnion(msg.sender,periodInfo.roundList[roundNumber].address_participantInfo[msg.sender].amount.mul(6).div(1000));

        if (periodInfo.roundList[roundNumber].totalPlayer==5){

            fighting(amount,roundNumber);
        }
    }
    function fighting(uint256 amount,uint roundNumber) private {
        PERIOD storage periodInfo=periods[amount];
        Round  storage period=periodInfo.roundList[roundNumber];
        uint256 minspeed=0;
        address winner;
        for (uint i=0;i<period.player.length;i++){
            uint256 speed=period.address_participantInfo[period.player[i]].speed;
             if(minspeed<=speed){
                 minspeed=speed;
                 winner=period.player[i];
             }
        }
        period.address_participantInfo[winner].isWinner=true;

        for(uint i=0;i<period.player.length;i++){
            if (!period.address_participantInfo[period.player[i]].isWinner){
               period.address_participantInfo[period.player[i]].rewardUSDT=period.address_participantInfo[period.player[i]].amount.add(period.address_participantInfo[period.player[i]].amount.mul(8).div(100));
               playerInfo[period.player[i]].totalUSDTReward=playerInfo[period.player[i]].totalUSDTReward.add(period.address_participantInfo[period.player[i]].rewardUSDT);
            }else{
                uint256 price=getPriceOfUSDT();
                uint256 rewardGameToken=period.address_participantInfo[period.player[i]].amount.mul(10**6).mul(2).div(price);
                period.address_participantInfo[period.player[i]].rewardGameToken=rewardGameToken;
                playerInfo[period.player[i]].totalGameTokenReward=playerInfo[period.player[i]].totalGameTokenReward.add(rewardGameToken);
                
                uint256 returnTime=block.timestamp+(86400-block.timestamp%86400);

                playerInfo[period.player[i]].GameTokenRewardList.push(GameTokenRewardInfo({amount:rewardGameToken,returnTime:returnTime,returnCount:0,remainingAmount:rewardGameToken}));
            }
            IERC721(nftAddress).transferFrom(
                          address(this),
                          address(0xdead),
                          period.address_participantInfo[period.player[i]].tokenId
            );
            period.address_participantInfo[period.player[i]].endtime=block.timestamp;
            playerInfo[period.player[i]].playHistoryInfo.push(period.address_participantInfo[period.player[i]]);
            uint256 lastRoundNumber =playerInfo[period.player[i]].pendingRoundList[amount][playerInfo[period.player[i]].pendingRoundList[amount].length-1];
            uint256 roundIndex=playerInfo[period.player[i]].pendingRoundIndex[roundNumber];
            playerInfo[period.player[i]].pendingRoundList[amount][roundIndex]=lastRoundNumber;
            playerInfo[period.player[i]].pendingRoundIndex[lastRoundNumber]=roundIndex;
            delete playerInfo[period.player[i]].pendingRoundIndex[roundNumber];
            playerInfo[period.player[i]].pendingRoundList[amount].pop();
        }


        uint256 ls=   amount.mul(10**6).mul(5).div(100);
        IERC20(usdtAddress).transfer(
                      address(beneficiary1_20),
                      ls.mul(20).div(100) );

        IERC20(usdtAddress).transfer(
                      address(beneficiary1_56),
                      ls.mul(56).div(100));

        

        IERC20(usdtAddress).transfer(
                      address(beneficiary1_24),
                     ls.mul(24).div(100) );



        swapAndSend(amount.mul(40).div(100));
        period.endTime=block.timestamp;
        uint256 lastRoundNumber =periodInfo.pendingRoundList[periodInfo.pendingRoundList.length-1];
        uint256 roundIndex=periodInfo.pendingRoundIndex[roundNumber];
        periodInfo.pendingRoundList[roundIndex]=lastRoundNumber;
        periodInfo.pendingRoundIndex[lastRoundNumber]=roundIndex;
        delete periodInfo.pendingRoundIndex[roundNumber];
        periodInfo.pendingRoundList.pop();
        periodInfo.roundNumber+=1;
        periodInfo.roundList[periodInfo.roundNumber].startTime=block.timestamp;
    }
 
  

    function dividendsToTeam(address from,uint256 usdtAmount)private{
        uint256 beforusdtAmount=usdtAmount;
        uint8 i=1;
        address userAddress=from;
        uint256 lastAmountDividend;
        while (true) {
            address referalAddress=playerInfo[userAddress].referrer;
            if (i==10||beforusdtAmount<=lastAmountDividend){
                break;
            }
            if (referalAddress!=address(0)){
                uint AmountDividend=getAmountDividendOfTeam(teamInfo[referalAddress].teamLevel,beforusdtAmount);
                if (lastAmountDividend>=AmountDividend){
                    AmountDividend=0;
                }else{
                    uint256 beferAmountDividend=AmountDividend;
                    AmountDividend=AmountDividend.sub(lastAmountDividend);
                    lastAmountDividend=beferAmountDividend;
                }
                teamInfo[referalAddress].totalUSDTReward=teamInfo[referalAddress].totalUSDTReward.add(AmountDividend);
            }
            userAddress=referalAddress;
            i++;
        }
        if (beforusdtAmount.sub(lastAmountDividend)>0){

            uint256   balance = beforusdtAmount.sub(lastAmountDividend);
 
            IERC20(usdtAddress).transfer(
                                beneficiary1_20,
                                balance.mul(20).div(100)
            );


            IERC20(usdtAddress).transfer(
                                beneficiary1_56,
                                balance.mul(56).div(100)
            );

            IERC20(usdtAddress).transfer(
                address(beneficiary1_24),
                balance.mul(24).div(100) );
        }
    }


    function getAmountDividendOfTeam(string memory teamLevel,uint256 amount)private pure returns(uint256){
        uint amountDividend;
        
        if(keccak256(abi.encodePacked(teamLevel))==keccak256(abi.encodePacked("zero"))){
            return amountDividend;
        }else if(keccak256(abi.encodePacked(teamLevel))==keccak256(abi.encodePacked("A"))){
             amountDividend=amount.mul(100).div(100);
         }else if(keccak256(abi.encodePacked(teamLevel))==keccak256(abi.encodePacked("B"))){
             amountDividend=amount.mul(80).div(100);
         }else if(keccak256(abi.encodePacked(teamLevel))==keccak256(abi.encodePacked("C"))){
             amountDividend=amount.mul(60).div(100);
         }else if(keccak256(abi.encodePacked(teamLevel))==keccak256(abi.encodePacked("D"))){
             amountDividend=amount.mul(40).div(100);
         }else if(keccak256(abi.encodePacked(teamLevel))==keccak256(abi.encodePacked("E"))){
             amountDividend=amount.mul(20).div(100);
         }
         return amountDividend;
    }

    function dividendsToUnion(address from,uint256 usdtAmount)private{
        uint8 i=1;
        uint8 k=1;
        address userAddress=from;
        uint256 lastAmountDividend=usdtAmount;
        while (true) {
            address referalAddress=playerInfo[userAddress].referrer;
            if (i==10||k==3){
                break;
            }
            if(playerInfo[referalAddress].isUnion==true&&k==2){
                playerInfo[referalAddress].totalUnionReward=playerInfo[referalAddress].totalUnionReward.add(usdtAmount.mul(1).div(3));
                lastAmountDividend=lastAmountDividend.sub(usdtAmount.mul(1).div(3));
                k+=1;
            }
            if(playerInfo[referalAddress].isUnion==true&&k==1){
                playerInfo[referalAddress].totalUnionReward=playerInfo[referalAddress].totalUnionReward.add(usdtAmount.mul(2).div(3));
                lastAmountDividend=lastAmountDividend.sub(usdtAmount.mul(2).div(3));
                k+=1;
            }

            userAddress=referalAddress;
            i++;
        }
        if (lastAmountDividend>0){
            IERC20(usdtAddress).transfer(
                                beneficiary1_20,
                                lastAmountDividend.mul(20).div(100)
            );
            IERC20(usdtAddress).transfer(
                                beneficiary1_56,
                                lastAmountDividend.mul(56).div(100));
         IERC20(usdtAddress).transfer(
                                beneficiary1_24,
                                lastAmountDividend.mul(24).div(100));

        }
    }



    function getParticipantInfo(address player,uint256 periodNumber,uint256 amount) public view returns(ParticipantInfo memory){

        PERIOD storage periodInfo=periods[amount];
        return periodInfo.roundList[periodNumber].address_participantInfo[player];

    }

    function getReferralRewardList(address player) public view returns(ReferralReward[] memory){
        return playerInfo[player].referralRewardList;

    }

    function getRoundPlayer(uint256 periodNumber,uint256 amount) public view returns(address[] memory){

        PERIOD storage periodInfo=periods[amount];
        return periodInfo.roundList[periodNumber].player;
    }

    function getRoundNumber(uint256 amount)public view returns(uint roundNumber){
        PERIOD storage periodInfo=periods[amount];
        return periodInfo.roundNumber;
    }

    function getPlayHistoryInfo(address player) public view returns(ParticipantInfo[] memory){
        return playerInfo[player].playHistoryInfo;
    }

    function getPlayerPendingRoundList(address player,uint amount) public view returns(uint[] memory){
        return playerInfo[player].pendingRoundList[amount];
    }

    function getPendingRoundList(uint amount) public view returns(uint[] memory){
        PERIOD storage periodInfo=periods[amount];
        return periodInfo.pendingRoundList;
    }
    
    function getRoundListTotalPlayer(uint amount) public view returns(uint totalPlayer){
        PERIOD storage periodInfo=periods[amount];
        return periodInfo.roundList[periodInfo.roundNumber].totalPlayer;
    }

    function getReturnGameToken(address player) public view returns(uint256){
        uint256 returnAmount;
        GameTokenRewardInfo[] storage GameTokenRewardList= playerInfo[player].GameTokenRewardList;

        for (uint i=0;i<GameTokenRewardList.length;i++){
            GameTokenRewardInfo storage gameTokenRewardInfo=GameTokenRewardList[i];
            if (gameTokenRewardInfo.returnTime>block.timestamp){
                continue;
            }
            uint256 returnCount=1;

            if (block.timestamp>gameTokenRewardInfo.returnTime){
            returnCount=returnCount.add((block.timestamp-gameTokenRewardInfo.returnTime).div(24 hours));
            }
            if (gameTokenRewardInfo.amount.mul(1).div(100).mul(returnCount)>gameTokenRewardInfo.remainingAmount){
              returnAmount=returnAmount.add(gameTokenRewardInfo.remainingAmount);
            }else{
              returnAmount=returnAmount.add(gameTokenRewardInfo.amount.mul(1).div(100).mul(returnCount));
            }
        }
        return returnAmount;
    }
    function getRemainingGameToken(address player) public view returns(uint256){
        uint256 remainingAmount;
        GameTokenRewardInfo[] storage GameTokenRewardList= playerInfo[player].GameTokenRewardList;

        for (uint i=0;i<GameTokenRewardList.length;i++){
            GameTokenRewardInfo storage gameTokenRewardInfo=GameTokenRewardList[i];
            remainingAmount=remainingAmount.add(gameTokenRewardInfo.remainingAmount);
        }
        return remainingAmount;
    }

    function withdrawReturnGameToken() public {
        require(!address(msg.sender).isContract(),"Address: The transferred address cannot be a contract");
        uint256 totalReturnAmount;

        GameTokenRewardInfo[] storage GameTokenRewardList= playerInfo[msg.sender].GameTokenRewardList;

        for (uint i=0;i<GameTokenRewardList.length;i++){
            GameTokenRewardInfo storage gameTokenRewardInfo=GameTokenRewardList[i];
            uint256 returnCount=1;
            uint256 returnAmount;
            if (gameTokenRewardInfo.returnTime>block.timestamp){
                continue; 
            }
            if (block.timestamp>gameTokenRewardInfo.returnTime){
             returnCount=returnCount.add((block.timestamp-gameTokenRewardInfo.returnTime).div(24 hours));
            }
            if (gameTokenRewardInfo.amount.mul(1).div(100).mul(returnCount)>gameTokenRewardInfo.remainingAmount){
             returnAmount=gameTokenRewardInfo.remainingAmount;
            }else{
              returnAmount=gameTokenRewardInfo.amount.mul(1).div(100).mul(returnCount);
            }
            totalReturnAmount=totalReturnAmount.add(returnAmount);
            gameTokenRewardInfo.remainingAmount=gameTokenRewardInfo.remainingAmount.sub(returnAmount);
            gameTokenRewardInfo.returnTime=gameTokenRewardInfo.returnTime.add(24 hours*returnCount);
        }
        require(totalReturnAmount>0,"totalReturnAmount err");

        IERC20(gameTokenAddress).transfer(
                            msg.sender,
                            totalReturnAmount
        );
        playerInfo[msg.sender].extractedGameTokenReturn=playerInfo[msg.sender].extractedGameTokenReturn.add(totalReturnAmount);
    }

    function withdrawPlayerUSDT() public {
        require(!address(msg.sender).isContract(),"Address: The transferred address cannot be a contract");
        uint256 totalUSDTReward=playerInfo[msg.sender].totalUSDTReward;

        require(totalUSDTReward>0,"return Amount err");

        IERC20(usdtAddress).transfer(
                msg.sender,
                totalUSDTReward
        );
        playerInfo[msg.sender].extractedUSDTReward=playerInfo[msg.sender].extractedUSDTReward.add(totalUSDTReward);
        playerInfo[msg.sender].totalUSDTReward=0;
    }

    function withdrawReferralReward() public {
        require(!address(msg.sender).isContract(),"Address: The transferred address cannot be a contract");

        uint256 totalReferralReward=playerInfo[msg.sender].totalReferralReward;
         require(totalReferralReward>0,"returnAmount err");
        IERC20(usdtAddress).transfer(
                msg.sender,
                totalReferralReward
        );
        playerInfo[msg.sender].extractedUSDTReward=teamInfo[msg.sender].extractedUSDTReward.add(totalReferralReward);
        playerInfo[msg.sender].totalReferralReward=0;


    }

    function withdrawTeamUSDT() public {
        require(!address(msg.sender).isContract(),"Address: The transferred address cannot be a contract");
        uint256 totalUSDTReward=teamInfo[msg.sender].totalUSDTReward;
        IERC20(usdtAddress).transfer(
                msg.sender,
                totalUSDTReward 
        );
        teamInfo[msg.sender].extractedUSDTReward=teamInfo[msg.sender].extractedUSDTReward.add(totalUSDTReward);
        teamInfo[msg.sender].totalUSDTReward=0;

    }
        function withdrawUnionUSDT() public {
        require(!address(msg.sender).isContract(),"Address: The transferred address cannot be a contract");
        uint256 totalUnionReward=playerInfo[msg.sender].totalUnionReward;
        uint256 extractedUnionReward=playerInfo[msg.sender].extractedUnionReward;
        require(totalUnionReward > 0,"returnAmount err");

        IERC20(usdtAddress).transfer(
                msg.sender,
                totalUnionReward
        );
        playerInfo[msg.sender].extractedUnionReward = extractedUnionReward.add(totalUnionReward);
        playerInfo[msg.sender].totalUnionReward=0;
    }



    function swapAndSend(uint256 contractTokenBalance) private{
   
        uint256 initialBalance = IERC20(gameTokenAddress).balanceOf(address(this));

        // swap tokens for USDT
        swapTokensForExactTokens(contractTokenBalance); 

        uint256 newBalance = IERC20(gameTokenAddress).balanceOf(address(this)).sub(initialBalance);

         IERC20(gameTokenAddress).transfer(
                      address(0xdead),
                      newBalance
         );
    }

    function swapTokensForExactTokens(uint256 tokenAmount) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = usdtAddress;
        path[1] = gameTokenAddress;

 
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function tobeUnion(uint256 amount) public {
        require(amount>=unionFee,"Fee err");
        Player storage player=playerInfo[msg.sender];
        require(player.isUnion==false,"You have become an alliance union");
        bool isExists =isUserExists(msg.sender);
        require(isExists,"you are not registered fail");
        IERC20(usdtAddress).transferFrom(
                address(msg.sender),
                address(beneficiary1_20),
                amount.mul(200).div(1000) 
        );
        IERC20(usdtAddress).transferFrom(
                address(msg.sender),
                address(beneficiary1_56),
                amount.mul(560).div(1000) 

        );
          IERC20(usdtAddress).transferFrom(
                address(msg.sender),
                address(beneficiary1_24),
                amount.mul(240).div(1000) 
        );
        
        player.isUnion=true;
    }

    function bind(address _referrerAddress) public {
        require(!address(msg.sender).isContract(),"Address: The transferred address cannot be a contract");
        bool isExists =isUserExists(msg.sender);
        require(!isExists,"you are already registered");
        require(_referrerAddress != msg.sender,"you are   registered fial");
        require(isUserExists(_referrerAddress)||_referrerAddress==defaultReferrerAddress,"ReferrerAddress don't exist");
        
        Player storage player=playerInfo[msg.sender];
        if (!isExists){
            player.referrer=_referrerAddress;
            player.id=lastUserId;
            lastUserId++;
            teamInfo[msg.sender].teamLevel="zero";
            recommendedTeamLevel[player.referrer]["zero"]+=1;
            uint8 i=1;
            address previousReferrer=_referrerAddress;
            while (true) {
                if (i==11||previousReferrer==address(0)){
                    break;
                }

                TeamInfo storage team=teamInfo[previousReferrer];
                if(i==1){
                    playerInfo[previousReferrer].directRecommendAddress.push(msg.sender);
                    team.validDirectRecommend+=1;
                }
                team.agentSubordinateAddress.push(msg.sender);
                team.validAgentSubordinate+=1;
                string memory beforTeamLevel=team.teamLevel;
                if(playerInfo[previousReferrer].directRecommendAddress.length>=100&&recommendedTeamLevel[previousReferrer]["B"]>=5){
                team.teamLevel="A";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length==60&&(recommendedTeamLevel[previousReferrer]["B"]>=4||recommendedTeamLevel[previousReferrer]["C"]>=4)){
                    team.teamLevel="B";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length>=15&&(recommendedTeamLevel[previousReferrer]["D"]>=3||recommendedTeamLevel[previousReferrer]["B"]>=3||recommendedTeamLevel[previousReferrer]["C"]>=3)){
                    team.teamLevel="C";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length>=10&&(recommendedTeamLevel[previousReferrer]["E"]>=2||recommendedTeamLevel[previousReferrer]["D"]>=2||recommendedTeamLevel[previousReferrer]["B"]>=2||recommendedTeamLevel[previousReferrer]["C"]>=2)){
                    team.teamLevel="D";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length>=5&&team.agentSubordinateAddress.length>=20){
                    team.teamLevel="E";
                }
                previousReferrer=playerInfo[previousReferrer].referrer;
                recommendedTeamLevel[previousReferrer][beforTeamLevel]-=1;
                recommendedTeamLevel[previousReferrer][team.teamLevel]+=1;
                i++;
            }
 
     
              allAddress.push(msg.sender);
         }
    }

 




 function updataLive(address _referrerAddress,string memory Level) public onlyOwner {
         Player storage player=playerInfo[_referrerAddress];
            teamInfo[_referrerAddress].teamLevel=Level;
            recommendedTeamLevel[player.referrer][Level]+=1;
            uint8 i=1;
            address previousReferrer=player.referrer;
            while (true) {
                if (i==11||previousReferrer==address(0)){
                    break;
                }

                TeamInfo storage team=teamInfo[previousReferrer];
                if(i==1){
                     team.validDirectRecommend+=1;
                }
                team.agentSubordinateAddress.push(_referrerAddress);
                team.validAgentSubordinate+=1;
                string memory beforTeamLevel=team.teamLevel;
                if(playerInfo[previousReferrer].directRecommendAddress.length>=25&&recommendedTeamLevel[previousReferrer]["B"]>=2){
                team.teamLevel="A";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length==20&&(recommendedTeamLevel[previousReferrer]["B"]>=2||recommendedTeamLevel[previousReferrer]["C"]>=2)){
                    team.teamLevel="B";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length>=15&&(recommendedTeamLevel[previousReferrer]["D"]>=2||recommendedTeamLevel[previousReferrer]["B"]>=2||recommendedTeamLevel[previousReferrer]["C"]>=2)){
                    team.teamLevel="C";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length>=10&&(recommendedTeamLevel[previousReferrer]["E"]>=2||recommendedTeamLevel[previousReferrer]["D"]>=2||recommendedTeamLevel[previousReferrer]["B"]>=2||recommendedTeamLevel[previousReferrer]["C"]>=2)){
                    team.teamLevel="D";
                }else if(playerInfo[previousReferrer].directRecommendAddress.length>=5&&team.agentSubordinateAddress.length>=20){
                    team.teamLevel="E";
                }
                previousReferrer=playerInfo[previousReferrer].referrer;
                recommendedTeamLevel[previousReferrer][beforTeamLevel]-=1;
                recommendedTeamLevel[previousReferrer][team.teamLevel]+=1;
                i++;
            }
     }

    function getDirectRecommendAddressList(address user)public view returns(address[] memory){
        return playerInfo[user].directRecommendAddress;
    }

    function getAgentSubordinateAddressList(address user)public view returns(address[] memory){
        return teamInfo[user].agentSubordinateAddress;
    }
    function getPriceOfUSDT() public view returns (uint){
 
        address[] memory path = new address[](2);
	    path[0] = gameTokenAddress;
	    path[1] = usdtAddress;

        uint[] memory amount1 = uniswapV2Router.getAmountsOut(1*10**6,path);

        return amount1[1];
    }

    function  getPriceOfUSDT2() public view returns (uint256 price){

        address uniswapV2Pair=IUniswapV2Factory(uniswapV2Router.factory()).getPair(gameTokenAddress,usdtAddress);
        uint256 balancePath1= IERC20(usdtAddress).balanceOf(uniswapV2Pair);
        uint256 balancePath2= IERC20(gameTokenAddress).balanceOf(uniswapV2Pair);
        if(balancePath1==0||balancePath2==0)return 0;
        uint256 path1Decimals=IERC20(usdtAddress).decimals();
        uint256 path2Decimals=IERC20(gameTokenAddress).decimals();
        price=(balancePath1*10**6/10**path1Decimals)/(balancePath2/10**path2Decimals);
    }
}