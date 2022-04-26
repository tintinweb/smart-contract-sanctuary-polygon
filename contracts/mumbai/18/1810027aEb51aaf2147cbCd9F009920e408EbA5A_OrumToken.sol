// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IOrumToken.sol";
import "./CheckContract.sol";
import "./SafeMath.sol";
import "./ILockupContractFactory.sol";

contract OrumToken is IOrumToken, CheckContract{
    using SafeMath for uint256;

    // --- ERC20 Data ---

    string constant internal _NAME = "Orum";
    string constant internal _SYMBOL = "ORUM";
    string constant internal _VERSION = "1";
    uint8 constant internal  _DECIMALS = 18;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint private _totalSupply;

    // --- EIP 2612 Data ---

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;

    address public communityIssuanceAddress;
    
    mapping (address => uint256) private _nonces;

    // --- ORUMToken specific data ---

    uint public constant ONE_YEAR_IN_SECONDS = 31536000;  // 60 * 60 * 24 * 365

    // uint for use with SafeMath
    uint internal _1_MILLION = 1e24;    // 1e6 * 1e18 = 1e24

    uint internal immutable deploymentStartTime;

    // address public immutable communityIssuanceAddress;
    address public orumStakingAddress;

    address public votedEscrowAddress;

    uint internal lpRewardsEntitlement;

    ILockupContractFactory public lockupContractFactory;

    address public bountiesAndGrantsAddress;

    // --- Functions ---

    constructor() 
    {
        deploymentStartTime  = block.timestamp;
        
        //communityIssuanceAddress = _communityIssuanceAddress;

        bytes32 hashedName = keccak256(bytes(_NAME));
        bytes32 hashedVersion = keccak256(bytes(_VERSION));

        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _chainID();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, hashedName, hashedVersion);
    }

    function setAdressesAndTransferTokens(
        address _communityIssuanceAddress, 
        address _lpRewardsAddress,
        address _bountiesAndGrantsAddress,
        address _lockupFactoryAddress,
        address _votedEscrowAddress
    ) external {
        checkContract(_communityIssuanceAddress);
        checkContract(_lpRewardsAddress);
        checkContract(_lockupFactoryAddress);
        checkContract(_votedEscrowAddress);
        bountiesAndGrantsAddress = _bountiesAndGrantsAddress;

        communityIssuanceAddress = _communityIssuanceAddress;
        lockupContractFactory = ILockupContractFactory(_lockupFactoryAddress);

        votedEscrowAddress = _votedEscrowAddress;

        // --- Initial ORUM allocations ---
     
        uint bountiesAndGrantsEntitlement = _1_MILLION.mul(55); // Allocate 55 million for bounties/hackathons
        // _mint(_bountyAddress, bountyEntitlement);
        _mint(bountiesAndGrantsAddress, bountiesAndGrantsEntitlement);

        uint depositorsEntitlement = _1_MILLION.mul(40); // Allocate 40 million to the algorithmic issuance schedule
        _mint(_communityIssuanceAddress, depositorsEntitlement);

        uint _lpRewardsEntitlement = _1_MILLION.mul(5);  // Allocate 5 million for LP rewards
        lpRewardsEntitlement = _lpRewardsEntitlement;
        _mint(_lpRewardsAddress, _lpRewardsEntitlement);
    }

    // --- External functions ---

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function getDeploymentStartTime() external view override returns (uint256) {
        return deploymentStartTime;
    }

    function getLpRewardsEntitlement() external view override returns (uint256) {
        return lpRewardsEntitlement;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        // Restrict the multisig's transfers in first year
        if (msg.sender == bountiesAndGrantsAddress && _isFirstYear()) {
        // Otherwise, standard transfer functionality
        _requireRecipientIsRegisteredLC(recipient);
        }
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        if (_isFirstYear()) { require(msg.sender != bountiesAndGrantsAddress, "Depositor cannot approve for one year"); }
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_isFirstYear()) { require(msg.sender != bountiesAndGrantsAddress, "Depositor cannot transferFrom for one year"); }
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "OrumToken: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        if (_isFirstYear()) { require(msg.sender != bountiesAndGrantsAddress, "Depositor cannot increaseAllowance for one year"); }
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        if (_isFirstYear()) { require(msg.sender != bountiesAndGrantsAddress, "Depo sitor cannot decreaseAllowance for one year"); }
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function sendToContract(address _sender,  address _votedEscrowAddress, uint256 _amount) external override {
        _requireCallerIsVotedEscrow();
        _transfer(_sender, _votedEscrowAddress, _amount);
    }

    function _requireCallerIsVotedEscrow() internal view {
        require(msg.sender == votedEscrowAddress, "oMATIC: Caller is not the BorrowerOps");
    }

    // --- EIP 2612 functionality ---

    function domainSeparator() public view override returns (bytes32) {    
        if (_chainID() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function permit
    (
        address owner, 
        address spender, 
        uint amount, 
        uint deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        external 
        override 
    {            
        require(deadline >= block.timestamp, 'Orum: expired deadline');
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', 
                         domainSeparator(), keccak256(abi.encode(
                         _PERMIT_TYPEHASH, owner, spender, amount, 
                         _nonces[owner]++, deadline))));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner, 'Orum: invalid signature');
        _approve(owner, spender, amount);
    }

    function nonces(address owner) external view override returns (uint256) { // FOR EIP 2612
        return _nonces[owner];
    }

    // --- Internal operations ---

    function _chainID() private view returns (uint256 chainID) {
        assembly {
            chainID := chainid()
        }
    }

    function _buildDomainSeparator(bytes32 _typeHash, bytes32 _name, bytes32 _version) private view returns (bytes32) {
        return keccak256(abi.encode(_typeHash, _name, _version, _chainID(), address(this)));
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _requireRecipientIsRegisteredLC(address _recipient) internal view {
        require(lockupContractFactory.isRegisteredLockup(_recipient), 
        "OrumToken: recipient must be a LockupContract registered in the Factory");
    }

    function _requireSenderIsNotMultisig(address _sender) internal view {
        require(_sender != bountiesAndGrantsAddress, "OrumToken: sender must not be the multisig");
    }

    function _requireCallerIsNotMultisig() internal view {
        require(msg.sender != bountiesAndGrantsAddress, "OrumToken: caller must not be the multisig");
    }

    function _requireCallerIsOrumStaking() internal view {
         require(msg.sender == orumStakingAddress, "OrumToken: caller must be the OrumStaking contract");
    }
    
    // --- Helper functions ---

    function _isFirstYear() internal view returns (bool) {
        return (block.timestamp.sub(deploymentStartTime) < ONE_YEAR_IN_SECONDS);
    }

    // --- 'require' functions ---

    // --- Optional functions ---

    function name() external pure override returns (string memory) {
        return _NAME;
    }

    function symbol() external pure override returns (string memory) {
        return _SYMBOL;
    }

    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    function version() external pure override returns (string memory) {
        return _VERSION;
    }

    function permitTypeHash() external pure override returns (bytes32) {
        return _PERMIT_TYPEHASH;
    }
}