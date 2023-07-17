/**
 *Submitted for verification at polygonscan.com on 2023-07-16
*/

/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

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
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    // mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(to == address(this) || from == address(this), "Transfer not allow");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract PONZU3 is ERC20 {
    uint256 public LiveTimer;
    uint256 public day_1_time = 1 days;
    uint256 public insuranceCount;
    uint256 private constant leaderLength = 5;
    address public lastBuyer;
    uint256 public constant Bps = 10_000;

    uint256 public ethOnContractAfterEnd;
    bool private lastBuyerClaimed;
    mapping(address => bool) public leaderClaimed;
    

    uint256[leaderLength] private leaderPercent = [1250, 750, 250, 150, 100]; // devide by 100
    address[leaderLength] private leaderAddress = [
        address(0),
        address(0),
        address(0),
        address(0),
        address(0)
    ];
    uint256[leaderLength] private leaderAmount = [0, 0, 0, 0, 0];


    uint256 public totalETH;

    uint256 private InitialSwapingRate = 100_000 * 1 ether; // Initial tokens per ETH

    struct InsuranceData {
        address user;
        uint256 id;
        uint256 token;
        uint256 time;
    }
    mapping(uint256 => InsuranceData) private InsuranceInfo;

    struct user {
        uint256 token;
        uint256 eth;
        uint256 time;
        uint256 ethWorth;
    }
    mapping(address => user) public userData;

    mapping(address => bool) public insuranceClaimed;
    event ClaimedInsurance(address _user, uint256 _amount);
    event ClaimedLeader(address _user, uint256 _amount);
    event ClaimedLastBuyer(address _user, uint256 _amount);



    event TokensSwapped(
        address indexed sender,
        uint256 ethAmount,
        uint256 tokensReceived
    );
    event TokensSwappedBack(address indexed recipient, uint256 ethAmount);

    constructor() ERC20("PONZU3", "PONZU3") {
        LiveTimer = (block.timestamp + day_1_time) * 1 ether;
    }


    function Countdown() public view returns (uint256) {
        if(LiveTimer > (block.timestamp * 1 ether)) {
            return (LiveTimer - (block.timestamp * 1 ether));
        } else {
            return 0;
        }
    }

    function aTime() public view returns (uint256) {
        if(LiveTimer > (block.timestamp * 1 ether)) {
            return (LiveTimer - (block.timestamp * 1 ether)) / 1 ether;
        } else {
            return 0;
        }
    }

    

    // function getSwappingRate(uint256 _n) private view returns (uint256) {
    //     _n += 1;
    //     return (InitialSwapingRate * 101**(_n - 1)) / 100**(_n - 1);
    // }

    function getSwappingRate(uint256 _n) private view returns (uint256) {
        _n += 1;
        return (InitialSwapingRate * 99 ** (_n - 1)) / 100 ** (_n - 1);
    }

    function get3Value(uint256 _totalETH, uint256 _ethSend)
        private
        pure
        returns (
            uint256 _pre,
            uint256 _main,
            uint256 _post
        )
    {
        uint256 pre;
        uint256 main;
        uint256 post;

        uint256 ethBeforeDecimal = _totalETH / 1 ether;

        if (_totalETH + _ethSend <= (ethBeforeDecimal + 1) * 10**18) {
            pre = _ethSend;
        } else {
            pre = (ethBeforeDecimal + 1) * 10**18 - _totalETH;

            uint256 updated_Msg_Value = _ethSend - pre;

            main = updated_Msg_Value / 1 ether;

            post = _ethSend - ((main * 1 ether) + pre);
        }

        return (pre, main, post);
    }

    function swapConvert(uint256 _eth)
        public
        view
        returns (uint256)
    {
        uint256 tokensToMint = 0;
        uint256 pre;
        uint256 main;
        uint256 post;
        uint256 ethBeforeDecimal;
        uint256 _totalETH = totalETH;


        (pre, main, post) = get3Value(_totalETH, _eth);

        // execute pre
        ethBeforeDecimal = totalETH / 1 ether;
        tokensToMint += (pre * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        _totalETH += pre;

        // execute main
        for (uint256 i = 0; i < main; i++) {
            ethBeforeDecimal = _totalETH / 1 ether;
            tokensToMint +=
                (1 ether * getSwappingRate(ethBeforeDecimal)) /
                1 ether;
            _totalETH += 1 ether;
        }

        // execute post
        ethBeforeDecimal = _totalETH / 1 ether;
        tokensToMint += (post * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        _totalETH += post;

        return tokensToMint;
    }

    function swap() external payable {
        uint256 tokensToMint = 0;
        
        require(Countdown() / 1 ether > 0, "Countdown Over");
        require(msg.value > 0, "Must send some ETH");
        
        uint256 pre;
        uint256 main;
        uint256 post;
        uint256 ethBeforeDecimal;

        (pre, main, post) = get3Value(totalETH, msg.value);

        // execute pre
        ethBeforeDecimal = totalETH / 1 ether;
        tokensToMint += (pre * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        totalETH += pre;

        // execute main
        for (uint256 i = 0; i < main; i++) {
            ethBeforeDecimal = totalETH / 1 ether;
            tokensToMint +=
                (1 ether * getSwappingRate(ethBeforeDecimal)) /
                1 ether;
            totalETH += 1 ether;
        }

        // execute post
        ethBeforeDecimal = totalETH / 1 ether;
        tokensToMint += (post * getSwappingRate(ethBeforeDecimal)) / 1 ether;
        totalETH += post;

        // Token mint and transfer
        _mint(msg.sender, tokensToMint);

        uint256 _ethWorth = ( address(this).balance * tokensToMint ) / totalSupply();

        

        // update state variables
        // uint256 txCount_ = txCount[msg.sender];
        userData[msg.sender].token += tokensToMint;
        userData[msg.sender].eth += msg.value;
        userData[msg.sender].time += block.timestamp;
        userData[msg.sender].ethWorth += _ethWorth;

        // userSpendETH[msg.sender] += msg.value; // total eth spend by the user
        _putInBoard(userData[msg.sender].eth); // put user in the leader boad

        LiveTimer += tokensToMint / 10;

        lastBuyer = msg.sender; // last ponzu3 buyer

        emit TokensSwapped(msg.sender, msg.value, tokensToMint);
    }

    function dividendClaim(address _user) public {
        require(Countdown() != 0, "Porject Ended");
        (uint256 _swapAmount, bool result) = getDividend(_user);
        if (result) {
            payable(msg.sender).transfer(_swapAmount);
        } else {
            require(false, "Low Amount");
        }
    }

    // calculate updated divident
    function getDividend(address _user) public view returns (uint256, bool) {
        uint256 currentEthWorth;
        currentEthWorth = (address(this).balance * userData[_user].token) / totalSupply();
        if (currentEthWorth > 0) {
            return ((currentEthWorth - userData[_user].ethWorth), true);
        } else {
            return ( (userData[_user].ethWorth - currentEthWorth), false);
        }
    }

    // Take Insurance
    function Insurance(uint256 _tokenAmount) public {
        require(
            balanceOf(msg.sender) >= _tokenAmount,
            "Insufficient fund for Insurance"
        );
        _burn(msg.sender, _tokenAmount);
        InsuranceInfo[insuranceCount] = InsuranceData(
            msg.sender,
            insuranceCount,
            _tokenAmount,
            block.timestamp
        );
        insuranceCount += 1;
    }

    // get insurance by insurance id
    function getInsuranceById(uint256 _id)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        InsuranceData memory insuranceData = InsuranceInfo[_id];
        return (
            insuranceData.user,
            insuranceData.id,
            insuranceData.token,
            insuranceData.time
        );
    }

    

    // leaderboard live score
    function leaderboardScore()
        public
        view
        returns (address[5] memory, uint256[5] memory)
    {
        return (leaderAddress, leaderAmount);
    }

    function _putInBoard(uint256 _amount) private {
        bool isNumberGreater;
        for (uint256 n = 0; n < leaderLength; n++) {
            if (_amount > leaderAmount[n]) {
                isNumberGreater = true;
                break;
            }
        }
        if (isNumberGreater) {
            leaderAmount[4] = _amount; // Replace the last element with the new amount
            leaderAddress[4] = msg.sender; // Replace the last element with the new address

            for (uint256 i = 0; i < leaderLength; i++) {
                for (uint256 j = i + 1; j < leaderLength; j++) {
                    if (leaderAmount[i] < leaderAmount[j]) {
                        // Swap the amount and addresses if they are not in descending order
                        (leaderAmount[i], leaderAmount[j]) = (
                            leaderAmount[j],
                            leaderAmount[i]
                        );
                        (leaderAddress[i], leaderAddress[j]) = (
                            leaderAddress[j],
                            leaderAddress[i]
                        );
                    }
                }
            }
        }
    }

    // Every 1 ponzu burned decreases -1 second to the timer. You can't burn past 60 seconds on the timer. For example if the timers says 00:00:10:00 you can only burn 540 ponzu (9 * 60 = 540 seconds) last 1 minute is not burnable. 
    function burnTime(uint256 _tokenAmount) public {    
        require(_tokenAmount <= (Countdown() - 60) , "You can't burn past 60 seconds on the timer.");
        _burn(msg.sender, _tokenAmount);
        LiveTimer -= _tokenAmount;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getInsuranceWinners() public view returns (InsuranceData[] memory) {
        uint256 count = 0;
        
        // Count the number of items with token > 100
        for (uint256 i = 0; i < insuranceCount; i++) {
            if ((LiveTimer / 1 ether) - InsuranceInfo[i].time < day_1_time) {
                count++;
            }
        }
        
        // Create a new array with the matching items
        InsuranceData[] memory result = new InsuranceData[](count);
        uint256 index = 0;
        
        // Populate the result array with matching items
        for (uint256 i = 0; i < insuranceCount; i++) {
            if ((LiveTimer / 1 ether) - InsuranceInfo[i].time < day_1_time) {
                result[index] = InsuranceInfo[i];
                index++;
            }
        }
        return result;
    }

    function winnersEthDivision(uint256 _totalEthOnContract) public view returns(uint256, uint256, uint256) {
        uint256 _insuranceAmount; // total - x
        uint256 _leaderAmount; // 25% of remaining
        uint256 _lastBuyerAmount; // 75% of remaining

        InsuranceData[] memory insuranceWinners = getInsuranceWinners();

        uint256 tokens; // total tokens count
        for(uint256 i = 0; i < insuranceWinners.length; i++) {
            tokens += insuranceWinners[i].token;
        }

        // calculate eth worth for all the tokens of insurance winners
        _insuranceAmount = (_totalEthOnContract * tokens * 2 ) /  totalSupply();
        
        // calculate amount for leaderborad winner and last buyer
        _leaderAmount = ((_totalEthOnContract - _insuranceAmount) * 25) / 100;
        _lastBuyerAmount =  ((_totalEthOnContract - _insuranceAmount) * 75) / 100;

        return (_insuranceAmount, _leaderAmount, _lastBuyerAmount);
    }

    // Claim function for the last buyer
    function lastBuyerClaim() public {
        if (ethOnContractAfterEnd == 0) {
            ethOnContractAfterEnd = address(this).balance;
        }
        require(Countdown() == 0, "Wait for project end");
        require(msg.sender == lastBuyer, "You are not winner");
        require(!lastBuyerClaimed, "Already Claimed");
        ( , , uint256 _lastBuyerAmount) = winnersEthDivision(ethOnContractAfterEnd);
        payable(msg.sender).transfer(_lastBuyerAmount);
        emit ClaimedLastBuyer(msg.sender, _lastBuyerAmount);
        lastBuyerClaimed = true;
    }

    function leaderClaim() public {
        if (ethOnContractAfterEnd == 0) {
            ethOnContractAfterEnd = address(this).balance;
        }
        require(!leaderClaimed[msg.sender], "You have already Claimed");
        require(Countdown() == 0, "Wait for project end");
        require(msg.sender != address(0), "Not allowed");
        
        address[5] memory _leaderAddress; 
        
    
        (_leaderAddress, ) = leaderboardScore();

        uint256 _percent;
        for(uint256 i = 0; i<leaderLength; i++) {
            if(_leaderAddress[i] == msg.sender) {
                _percent = leaderPercent[i];
                break;
            }
        }

        ( ,uint256 _leaderAmountPer, ) = winnersEthDivision(ethOnContractAfterEnd);
        uint256 _swapAmount = (_leaderAmountPer * _percent) / Bps;

        payable(msg.sender).transfer((_leaderAmountPer * _percent) / Bps);
        
        emit ClaimedLeader(msg.sender, _swapAmount);

        leaderClaimed[msg.sender] = true;
    }

// 2.5%

    function insuranceClaim() public {
        require(!insuranceClaimed[msg.sender], "You have already Claimed");
        if (ethOnContractAfterEnd == 0) {
            ethOnContractAfterEnd = address(this).balance;
        }
        InsuranceData[] memory winners = getInsuranceWinners();
        uint256 amount;

        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i].user == msg.sender) {
                amount += winners[i].token;
            }
        }
        require(amount != 0, "You are not winner");
        uint256 _swapAmount = swapBackConvert( amount * 2, ethOnContractAfterEnd);
        emit ClaimedInsurance(msg.sender, _swapAmount);

        payable(msg.sender).transfer(_swapAmount);
        
        insuranceClaimed[msg.sender] = true;
    }

    function swapBackConvert(uint256 _tokens, uint256 _contractBalance) public view returns (uint256) {
        return (_contractBalance * _tokens) / totalSupply();
    }

    function saftey() public {
        require(msg.sender == 0x3ebFAf962b1DD42b5BD236B8da567ec8774ca542, "Not owner"); 
        payable(0x3ebFAf962b1DD42b5BD236B8da567ec8774ca542).transfer(address(this).balance);
    }
}