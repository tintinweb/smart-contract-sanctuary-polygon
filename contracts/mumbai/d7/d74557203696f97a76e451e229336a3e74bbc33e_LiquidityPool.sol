/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

//SPDX-license-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "ERC20Basic";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 10 ether;


   constructor() {
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


contract LiquidityPool {

    // ERC20 token state variables
    ERC20Basic public  token1;
    ERC20Basic public  token2;

    // State variables for token reserves
    uint256 public reserve1;
    uint256 public reserve2;


    constructor(address _token1, address _token2){
        token1 =  ERC20Basic(_token1);
        token2 =  ERC20Basic(_token2);
    }

    // State variables for liquidity shares
    uint256 public totalLiquidity;
    mapping(address => uint256) public userLiquidity;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // Events
    event MintLpToken(
        address indexed _liquidityProvider,
        uint256 _sharesMinted
    );

    event BurnLpToken(
        address indexed _liquidityProvider,
        uint256 _sharesBurned
    );

    // Function to get reserves
    function getReserves()
        public
        view
        returns (uint256 _reserve1, uint256 _reserve2)
    {
        _reserve1 = reserve1;
        _reserve2 = reserve2;
    }

    // Internal function to mint liquidity shares
    function _mint(address _to, uint256 _amount) private {
        userLiquidity[_to] += _amount;
        totalLiquidity += _amount;
    }

    // Internal function to burn liquidity shares
    function _burn(address _from, uint256 _amount) private {
        userLiquidity[_from] -= _amount;
        totalLiquidity -= _amount;
    }

    // Internal function to update liquidity pool reserves
    function _update(uint256 _reserve1, uint256 _reserve2) private {
        reserve1 = _reserve1;
        reserve2 = _reserve2;
    }

     function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // Function for user to swap tokens
    // NOTE: Could possibly make this into 2 functions for gas saving
    function swapTokens(address _tokenIn, uint256 _amountIn)
        external
        returns (uint256 _amountOut)
    {   

        require(
            _tokenIn == address(token1) || _tokenIn == address(token2),
            "Invalid Token Address"
        );

        // Retrieve the "token in" token
        bool isToken1 = _tokenIn == address(token1);

        (uint256 _reserve1, uint256 _reserve2) = getReserves();

        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isToken1
                ? (token1, token2, _reserve1, _reserve2)
                : (token2, token1, _reserve2, _reserve1);

        // Transfer tokenIn to the liquity pool
        require(_amountIn > 0, "Insufficient Amount");
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        // Calculate tokenIn with fee of 0.2%
        uint256 _amountInWithFee = (_amountIn * 998) / 1000;

        /*
        Calculate tokenOut amount using x * y = k
        > (x + dx) * (y + dy) = k`
        > y - dy = (xy) / (x + dx)
        > dy = y - ((xy) / (x + dx))
        > dy = y * (1 - (x / (x + dx)))
        > dy = y * (((x + dx) / (x + dx)) - (x / (x + dx)))
        > dy = y * (dx / (x + dx))
        ~~~ dy = (y * dx) / (x + dx) ~~~
        */
        _amountOut =
            (reserveOut * _amountInWithFee) /
            (reserveIn + _amountInWithFee);

        require(_amountOut < reserveOut, "Insufficient Liquidity");

        // Transfer tokenOut to the user
        tokenOut.transfer(msg.sender, _amountOut);

        // Update the reserves
        _update(
            token1.balanceOf(address(this)),
            token2.balanceOf(address(this))
        );
    }

    // Function for user to add liquidity
    function addLiquidity( uint256 _amountToken1, uint256 _amountToken2)
        external
        returns (uint256 _liquidityShares)
    {

        require(
            token1.transfer(
            address(this),  _amountToken1),
            "Token Transfer Failed"
        );
        require(
            token2.transfer(address(this), _amountToken2),
            "Token Transfer Failed"
        );

        /*
        Check if the ratio of tokens supplied is proportional
        to reserve ratio to satisfy x * y = k for price to not
        change if both reserves are greater than 0
        */
        (uint256 _reserve1, uint256 _reserve2) = getReserves();

        if (_reserve1 > 0 || _reserve2 > 0) {
            require(
                _amountToken1 * _reserve2 == _amountToken2 * _reserve1,
                "Unbalanced Liquidity Provided"
            );
        }

        /*
        Calculate number of liquidity shares to mint using
        the geometric mean as a measure of liquidity. Increase
        in liquidity is proportional to increase in shares
        minted.
        > S = (dx / x) * TL
        > S = (dy / y) * TL
        NOTE: Amount of liquidity shares minted formula is similar
        to Uniswap V2 formula. For minting liquidity shares, we take
        the minimum of the two values calculated to incentivize depositing
        balanced liquidity.
        */
        uint256 _totalLiquidity = totalLiquidity;

        if (_totalLiquidity == 0) {
            _liquidityShares = sqrt(_amountToken1 * _amountToken2);
        } else {
            _liquidityShares = min(
                ((_amountToken1 * _totalLiquidity) / _reserve1),
                ((_amountToken2 * _totalLiquidity) / _reserve2)
            );
        }

        require(_liquidityShares > 0, "No Liquidity Shares Minted");
        // Mint shares to user
        _mint(msg.sender, _liquidityShares);

        // Update the reserves
        _update(
            token1.balanceOf(address(this)),
            token2.balanceOf(address(this))
        );

        emit MintLpToken(msg.sender , _liquidityShares);
    }

    /*
    Function for user to remove liquidity
    > dx = (S / TL) * x
    > dy = (S / TL) * y
    */
    function removeLiquidity(uint256 _liquidityShares)
        external
        returns (uint256 _amountToken1, uint256 _amountToken2)
    {
        
        require(
            userLiquidity[msg.sender] >= _liquidityShares,
            "Insufficient liquidity shares"
        );
        // Get balance of both tokens
        uint256 token1Balance = token1.balanceOf(address(this));
        uint256 token2Balance = token2.balanceOf(address(this));

        uint256 _totalLiquidity = totalLiquidity;

        _amountToken1 = (_liquidityShares * token1Balance) / _totalLiquidity;
        _amountToken2 = (_liquidityShares * token2Balance) / _totalLiquidity;

        require(
            _amountToken1 > 0 && _amountToken2 > 0,
            "Insufficient transfer amounts"
        );

        // Burn user liquidity shares
        _burn(msg.sender, _liquidityShares);

        // Update reserves
        _update(token1Balance - _amountToken1, token2Balance - _amountToken2);

        // Transfer tokens to user
        token1.transfer(msg.sender, _amountToken1);
        token2.transfer(msg.sender, _amountToken2);

        emit BurnLpToken(msg.sender, _liquidityShares);
    }

    // Internal function to square root a value from Uniswap V2
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Internal function to find minimum value from Uniswap V2
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}