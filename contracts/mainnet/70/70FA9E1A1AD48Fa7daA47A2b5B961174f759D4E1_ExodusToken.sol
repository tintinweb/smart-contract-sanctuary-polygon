// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Owner.sol";
import "./Pausable.sol";

contract ExodusToken is ERC20, Owner, Pausable {

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _blacklist;

    address[30] public _walletListToSubtract;
    // properties used to get fee
    uint256 private constant amountDivToGetFee = 10**4;

    uint256 private constant MulByDec = 10**18;

    uint256[] public minAditionalFee = [
        100000*MulByDec,
        200000*MulByDec,
        300000*MulByDec,
        400000*MulByDec,
        500000*MulByDec,
        600000*MulByDec,
        700000*MulByDec,
        800000*MulByDec,
        900000*MulByDec,
        1000000*MulByDec,
        1100000*MulByDec,
        1200000*MulByDec,
        1300000*MulByDec,
        1500000*MulByDec,
        1700000*MulByDec,
        1900000*MulByDec,
        2100000*MulByDec,
        2300000*MulByDec,
        2600000*MulByDec,
        2900000*MulByDec,
        3200000*MulByDec,
        3500000*MulByDec
    ];
    uint256[] public amountMulToGetAditionalFee = [50,100,300,500,700,900,1100,1300,1500,1700,2000,2300,2600,3200,3800,4300,4700,5100,5600,6000,6400,8500];

    // tokenomics wallets
    address public constant reserve_wallet = 0xCAcd3d7CB6F798BBac53E882B2cBf5996d263F24;
    address public constant rewards_wallet = 0x264c84fBE8dAcdC4FD7559B204526AF1f61Ca5e7;
    address public constant ecosystem_wallet = 0xCd04Dac93f1172b7BA4218b84C81d68EBB32e8Cc;
    address public constant airdrop_wallet = 0xDF450B51b2f2FA1560EadA15E149d0064dF2327d;
    address public constant team1_wallet = 0x5Dbb556a3e832b8179B30c0E64C5668A6b3BdFD8;
    address public constant team2_wallet = 0xa4a01Cb9898CcF59e9780f22c828724f7794dC1F;
    address public constant team3_wallet = 0x7E8B53EE714Dd7B6D808cdf7a0043b7DC6680Eb1;
    address public constant team4_wallet = 0x69ac12d71D9A99B52339bDbFD0ECF2Af785De5aa;
    address public constant privateSale_wallet = 0x2511F8f04DAa128D2E7b9dD8C41d47734d37e50E;
    address public constant publicSale_wallet = 0xC4b1723f7EF8DaE035Af7e623b35C4F35C1F51f2;

    address public fees_wallet = 0xd2A9D580bBFb8dAE083e81599582283B2A16C644;

    // tokenomics supply
    uint public constant reserve_supply = 40000000 * MulByDec;
    uint public constant rewards_supply = 60000000 * MulByDec;
    uint public constant ecosystem_supply = 24000000 * MulByDec;
    uint public constant airdrop_supply = 2000000 * MulByDec;
    uint public constant team1_supply = 10000000 * MulByDec;
    uint public constant team2_supply = 10000000 * MulByDec;
    uint public constant team3_supply = 10000000 * MulByDec;
    uint public constant team4_supply = 10000000 * MulByDec;
    uint public constant privateSale_supply = 10000000 * MulByDec;
    uint public constant publicSale_supply = 24000000 * MulByDec;


    constructor() ERC20("Exodus", "EXS") {
        // set tokenomics balances
        _mint(reserve_wallet, reserve_supply);
        _mint(rewards_wallet, rewards_supply);
        _mint(ecosystem_wallet, ecosystem_supply);
        _mint(airdrop_wallet, airdrop_supply);
        _mint(team1_wallet, team1_supply);
        _mint(team2_wallet, team2_supply);
        _mint(team3_wallet, team3_supply);
        _mint(team4_wallet, team4_supply);
        _mint(privateSale_wallet, privateSale_supply);
        _mint(publicSale_wallet, publicSale_supply);

        _isExcludedFromFee[reserve_wallet] = true;
        _isExcludedFromFee[rewards_wallet] = true;
        _isExcludedFromFee[ecosystem_wallet] = true;
        _isExcludedFromFee[airdrop_wallet] = true;
        _isExcludedFromFee[team1_wallet] = true;
        _isExcludedFromFee[team2_wallet] = true;
        _isExcludedFromFee[team3_wallet] = true;
        _isExcludedFromFee[team4_wallet] = true;
        _isExcludedFromFee[privateSale_wallet] = true;
        _isExcludedFromFee[publicSale_wallet] = true;
        _isExcludedFromFee[fees_wallet] = true;

        _walletListToSubtract[0] = reserve_wallet;
        _walletListToSubtract[1] = rewards_wallet;
        _walletListToSubtract[2] = ecosystem_wallet;
        _walletListToSubtract[3] = airdrop_wallet;
        _walletListToSubtract[4] = team1_wallet;
        _walletListToSubtract[5] = team2_wallet;
        _walletListToSubtract[6] = team3_wallet;
        _walletListToSubtract[7] = team4_wallet;
        _walletListToSubtract[8] = privateSale_wallet;
        _walletListToSubtract[9] = publicSale_wallet;
        _walletListToSubtract[10] = fees_wallet;
    }

    function getTokensInCirculation() external view returns(uint256) {
        uint256 inCirculation = _totalSupply;
        for (uint256 i=0; i<_walletListToSubtract.length; i++) {
            if(_walletListToSubtract[i] != address(0)){
                inCirculation-=balanceOf(_walletListToSubtract[i]);
            }
        }
        return inCirculation;
    }
    function setWalletListToSubtract(uint256 _index, address _newValue) external isOwner {
        _walletListToSubtract[_index] = _newValue;
    }

    function setMinAditionalFee(uint256 _index, uint256 _newValue) external isOwner {
        minAditionalFee[_index] = _newValue;
    }
    function setPercentagesToGetAditionalFee(uint256 _index, uint256 _newValue) external isOwner {
        amountMulToGetAditionalFee[_index] = _newValue;
    }

    function excludeFromFee(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
             _isExcludedFromFee[accounts[i]] = true;
        }
    }
    function includeInFee(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = false;
        }
    }
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromBlacklist(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
             _blacklist[accounts[i]] = false;
        }
    }
    function includeInBlacklist(address[] memory accounts) external isOwner {
        for (uint256 i=0; i<accounts.length; i++) {
            _blacklist[accounts[i]] = true;
        }
    }
    function isOnBlacklist(address account) external view returns(bool) {
        return _blacklist[account];
    }

    function getAdditionalFee(uint256 _value) private view returns(uint256){
        uint256 aditionalFee = 0;
        for (uint256 i=0; i<minAditionalFee.length; i++) {
            if(_value >= minAditionalFee[i]){
                aditionalFee = (_value*amountMulToGetAditionalFee[i])/amountDivToGetFee;
            }else{
                break;
            }
        }
        return aditionalFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "ERC20: transfer amount must be greater than 0");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(!_blacklist[from] && !_blacklist[to], "ERC20: from or to address are in blacklist");
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }else{
            uint256 aditionalFee = getAdditionalFee(amount);
            if(aditionalFee>0){
                _balances[fees_wallet] += aditionalFee;
                emit Transfer(from, fees_wallet, aditionalFee);
            }
            _balances[to] += amount-aditionalFee;
            emit Transfer(from, to, amount-aditionalFee);
        }

        unchecked {
            _balances[from] = fromBalance-amount;
        }
        _afterTokenTransfer(from, to, amount);
    }


    // ********************************************************************
    // ********************************************************************
    // BURNEABLE FUNCTIONS

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    // ********************************************************************
    // ********************************************************************
    // PAUSABLE FUNCTIONS

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function pauseTransactions() external isOwner{
        _pause();
    }
    function unpauseTransactions() external isOwner{
        _unpause();
    }

}