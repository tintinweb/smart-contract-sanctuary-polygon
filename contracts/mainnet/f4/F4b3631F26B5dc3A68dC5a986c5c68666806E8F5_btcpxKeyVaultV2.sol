/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/nftKeyVaultUpdated.sol


pragma solidity ^0.8.9;




interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
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

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 tokenId) external;

    function mint(uint256 _count) external;
}

error youDontHaveBalance();
error youDontHaveApprovedTokens();
error WalletIsNotAnOwner();
error youAreNotOwner();
error pleaseWaitForReward();
error thisIdIsNotAllowedForStaking();
error YourAreNotAuthorized();

contract btcpxKeyVaultV2 is IERC721Receiver {
    address public owner;
    uint256 public price;
    uint256 public reward;
    uint256 public startRange;
    uint256 public endRange;
    bool public initialized;

    IERC721 public NFT;
    IERC20 public _USDC;
    IERC20 public _Btcpx;
    address public prxy;
    address public nftWalletAddress;

    uint256 public totalStakedTokens;
    uint256 public stakingId;
    uint256 public lastRewards;
    uint256 public stakerCount;
    uint256 public keysSold;

    mapping(uint256 => stake) public stakednfts;
    mapping(address => uint256) public remainingReward;
    mapping(address => uint256) public remainingRewardSecondToken;

    struct stake {
        uint256 tokenId;
        uint256 stakingStart;
        address stakerAddress;
        uint256 lastReward;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for owner");
        _;
    }

    IUniswapV2Router02 quickswap;

    // IUniswapV2Pair public pair =
    // IUniswapV2Pair(0x5428212fbb75046d6270C0bEf4Bc49882E2BB6a9);
    //0xA84BBe9361BbBd5EBC9eD78cA774e885Af87bC03 btcpx nft address
    //0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff quickswap Router Address
    //0x5428212fbb75046d6270C0bEf4Bc49882E2BB6a9 prxy/USDC pair address
    //0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 USDC address
    //0xab3D689C22a2Bb821f50A4Ff0F21A7980dCB8591 Prxy address

    function initialize() external {
        require(!initialized, "already initialized");
        owner = msg.sender;
        NFT = IERC721(0xA84BBe9361BbBd5EBC9eD78cA774e885Af87bC03); //0xA84BBe9361BbBd5EBC9eD78cA774e885Af87bC03
        _USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); //0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
        _Btcpx = IERC20(0x9C32185b81766a051E08dE671207b34466DD1021); //0x9C32185b81766a051E08dE671207b34466DD1021
        prxy = 0xab3D689C22a2Bb821f50A4Ff0F21A7980dCB8591;
        quickswap = IUniswapV2Router02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        nftWalletAddress = 0xf2E7008A2a2A2DCcC93C754c0C1E9C5417Aea6Dc; ///0xf2E7008A2a2A2DCcC93C754c0C1E9C5417Aea6Dc;
        reward = 10; //10%
        startRange = 6500;
        endRange = 9000;
        price = 100 * 10 ** 6;
        initialized = true;
    }

    function BuyNft(uint256 _tokenId) public {
        if (_tokenId < startRange || _tokenId > endRange) {
            revert thisIdIsNotAllowedForStaking();
        }
        if (NFT.ownerOf(_tokenId) != nftWalletAddress) {
            revert WalletIsNotAnOwner();
        }
        address sender = msg.sender;

        if (_USDC.allowance(sender, address(this)) < price) {
            revert youDontHaveApprovedTokens();
        }

        require(_USDC.transferFrom(sender, address(this), price));

        address[] memory path = new address[](2);
        path[0] = address(_USDC);
        path[1] = address(prxy);
        _USDC.approve(address(quickswap), price);
        quickswap.swapExactTokensForTokens(
            price,
            0,
            path,
            address(this),
            block.timestamp
        );

        NFT.transferFrom(nftWalletAddress, msg.sender, _tokenId);
        keysSold++;
    }

    //this price in wei of USDT
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    //set Reward in percentage
    function setReward(uint256 newReward) public onlyOwner {
        require(newReward < 100, "please enter valid Reward");
        reward = newReward;
    }

    function setRange(
        uint256 _setStartRange,
        uint256 _setEndRange
    ) public onlyOwner {
        startRange = _setStartRange;
        endRange = _setEndRange;
    }

    function WithdrawToken(address _token, uint256 _amount) public onlyOwner {
        if (IERC20(_token).balanceOf(address(this)) > _amount) {
            IERC20(_token).transfer(owner,_amount);
        } else {
            revert youDontHaveBalance();
        }
    }

    //////////////////////////// staking //////////////////////////

    function stakeNFT(uint256 _tokenId) external {
        if (_tokenId < startRange || _tokenId > endRange) {
            revert thisIdIsNotAllowedForStaking();
        }

        if (NFT.ownerOf(_tokenId) != msg.sender) {
            revert youAreNotOwner();
        }

        address[] memory path = new address[](2);
        path[0] = address(_USDC);
        path[1] = address(prxy);

        uint256[] memory amounts = quickswap.getAmountsOut(price, path);
        require(amounts[1] > 0, "Please check pool price");
        totalStakedTokens += amounts[1];

        NFT.transferFrom(msg.sender, address(this), _tokenId);

        stakingId++;
        stakerCount++;

        stakednfts[stakingId] = stake(_tokenId, block.timestamp, msg.sender, 0);
    }

    function allStakedBalance() public view returns (uint256) {
        return totalStakedTokens;
    }

    function secondTokenTotalBalance() public view returns (uint256) {
        // require(
        //     IERC20(_Btcpx).balanceOf(address(this)) > 0,
        //     "please send BTCpx to contract"
        // );
        return IERC20(_Btcpx).balanceOf(address(this));
    }

    function payoutPerYear() public view returns (uint256 _payOutAmount) {
        _payOutAmount = ((allStakedBalance() * reward) / 100);
    }

    function payoutPerday() public view returns (uint256 _payOutPerDay) {
        _payOutPerDay = (payoutPerYear() / 365) / stakerCount;
    }

    function secondTokenPayoutPerYear()
        public
        view
        returns (uint256 _payOutAmount)
    {
        _payOutAmount = ((secondTokenTotalBalance() * reward) / 100);
    }

    function secondTokenPayoutPerday()
        public
        view
        returns (uint256 _secondTokenPayoutPerday)
    {
        _secondTokenPayoutPerday =
            (secondTokenPayoutPerYear() / 365) /
            stakerCount;
    }

    function distributeRewards() public {
        for (uint256 i = 0; i <= stakingId; ++i) {
            stake storage s_Data = stakednfts[i];
            if (
                block.timestamp >= (s_Data.stakingStart + 1 days) &&
                s_Data.stakerAddress != address(0)
            ) {
                if (block.timestamp >= (s_Data.lastReward + 1 days)) {
                    remainingReward[s_Data.stakerAddress] += payoutPerday();
                    remainingRewardSecondToken[
                        s_Data.stakerAddress
                    ] += secondTokenPayoutPerday();
                    s_Data.lastReward = block.timestamp;
                }
            }
        }
    }

    function remainingRewardClaim() public {
        distributeRewards();
        if (
            remainingReward[msg.sender] <= 0 ||
            remainingRewardSecondToken[msg.sender] <= 0
        ) {
            revert pleaseWaitForReward();
        } else {
            uint256 amount = remainingReward[msg.sender];
            uint256 amount2 = remainingRewardSecondToken[msg.sender];
            remainingReward[msg.sender] = 0;
            remainingRewardSecondToken[msg.sender] = 0;
            IERC20(prxy).transfer(msg.sender, amount);
            IERC20(_Btcpx).transfer(msg.sender, amount2);
        }
    }

    function unstakeYourNFT(uint256 _stakingId) public {
        stake memory s_Data = stakednfts[_stakingId];
        if (
            address(this) != NFT.ownerOf(s_Data.tokenId) ||
            msg.sender != s_Data.stakerAddress
        ) {
            revert YourAreNotAuthorized();
        }
        require(
            block.timestamp > (s_Data.stakingStart + 1 days),
            "You can unstake after 24Hrs"
        );
        NFT.transferFrom(address(this), s_Data.stakerAddress, s_Data.tokenId);
        delete stakednfts[_stakingId];
        stakerCount--;
    }

    function ChangeOwner(address _addr) public onlyOwner {
        require(_addr != address(0), "Address Zero Not accept");
        owner = _addr;
    }

    function getMyNfts(address _addr) public view returns (stake[] memory) {
        uint256 myNftCount = 0;
        uint256 range = endRange - startRange;

        for (uint256 i = 0; i <= range; i++) {
            if (stakednfts[i].stakerAddress == _addr) {
                myNftCount++;
            }
        }

        stake[] memory nfts = new stake[](myNftCount);
        uint nftsIndex = 0;

        for (uint256 i = 0; i < range; i++) {
            if (stakednfts[i].stakerAddress == _addr) {
                nfts[nftsIndex] = stakednfts[i];
                nftsIndex++;
            }
        }

        return nfts;
    }

    function getNftsFromContract(
        address _addr
    ) public view returns (uint256[] memory) {
        uint256 myNftCount = 0;
        for (uint256 i = startRange; i <= endRange; i++) {
            if (NFT.ownerOf(i) == _addr) {
                myNftCount++;
            }
        }

        uint256[] memory defaultOperators = new uint256[](myNftCount);

        uint nftsIndex = 0;
        for (uint256 i = startRange; i < endRange; i++) {
            if (NFT.ownerOf(i) == _addr) {
                defaultOperators[nftsIndex] = i;
                nftsIndex++;
            }
        }
        return defaultOperators;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}