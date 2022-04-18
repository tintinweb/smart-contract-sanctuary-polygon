/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

// File: default_workspace/contracts/Ownable.sol


pragma solidity ^0.8.10;

error NotOwner();

// https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}

// File: default_workspace/contracts/tunnel/FxBaseChildTunnel.sol


pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// File: default_workspace/contracts/ERC20.sol


pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// File: default_workspace/contracts/DNGToken.sol


pragma solidity ^0.8.12;




/**
 ________  ________   ________          _________  ________  ___  __    _______   ________      
|\   ___ \|\   ___  \|\   ____\        |\___   ___\\   __  \|\  \|\  \ |\  ___ \ |\   ___  \    
\ \  \_|\ \ \  \\ \  \ \  \___|        \|___ \  \_\ \  \|\  \ \  \/  /|\ \   __/|\ \  \\ \  \   
 \ \  \ \\ \ \  \\ \  \ \  \  ___           \ \  \ \ \  \\\  \ \   ___  \ \  \_|/_\ \  \\ \  \  
  \ \  \_\\ \ \  \\ \  \ \  \|\  \           \ \  \ \ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \\ \  \ 
   \ \_______\ \__\\ \__\ \_______\           \ \__\ \ \_______\ \__\\ \__\ \_______\ \__\\ \__\
    \|_______|\|__| \|__|\|_______|            \|__|  \|_______|\|__| \|__|\|_______|\|__| \|__|
                                                                                                
**/

enum NftType {
    Dungeon,
    Avatar,
    Quest
}

contract DNGToken is ERC20, FxBaseChildTunnel, Ownable {

    address public childChainManagerProxy;

    struct Rewards {
        uint256 dungeon;
        uint256 avatar;
        uint256 quest;
    }

    Rewards public rewards;

    // staking balances for each NFT type, mapped to holder wallets.
    mapping(address => mapping(uint256 => uint256)) public balances;

    // timestamp when holder last withdrew their rewards.
    mapping(address => uint256) public lastUpdated;

    // feed in the FX Child from FX Portal so we can auto mint on polygon after staking --> https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal
    // and setup the child chain address so holders have option to withdraw back to the ETH token
    constructor(address _fxChild, address _childChainManagerProxy)
        FxBaseChildTunnel(_fxChild)
        ERC20("TNT Token", "TNT", 18)
    {
        childChainManagerProxy = _childChainManagerProxy;

        rewards.dungeon = (uint256(10) * 1e18) / 1 days;
        rewards.avatar = (uint256(5) * 1e18) / 1 days;
        rewards.quest = (uint256(3) * 1e18) / 1 days;

        _mint(address(this), 75_000_000 * 1e18);
        uint256 allocation = (35_000_000 + 4_000_000) *
            1e18;
        balanceOf[address(this)] -= allocation;

        unchecked {
            balanceOf[
                0xddd9d4D84a24385545780766cA302d36440ED4Ec
            ] += (35_000_000 * 1e18); // 35,000,000 reserved for p2e rewards
            balanceOf[
                0x887e50815a297822DA63fe892B827fb1A10c87ba
            ] += (4_000_000 * 1e18); // 4,000,000 reserved for team (in-game promotions, partnerships, growth)
        }

        emit Transfer(
            address(this),
            0xddd9d4D84a24385545780766cA302d36440ED4Ec,
            30_000_000 * 1e18
        );
        emit Transfer(
            address(this),
            0x887e50815a297822DA63fe892B827fb1A10c87ba,
            4_000_000 * 1e18
        );
    }

    // childchainmanager - for use with polygon bridge in case we ever want to bridge back to ETH version of token
    function updateChildChainManager(address _childChainManagerProxy) external onlyOwner {
        require(_childChainManagerProxy != address(0), "Bad ChildChainManagerProxy address.");

        childChainManagerProxy = _childChainManagerProxy;
    }
    // for use with polygon bridge
    // https://docs.matic.today/docs/develop/ethereum-matic/submit-mapping-request/    
    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == childChainManagerProxy, "Address not allowed to deposit.");

        uint256 amount = abi.decode(depositData, (uint256));

        _mint(user, amount);
    }
    // for use with polygon bridge
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    // end polygon bridge functions


    // updates rewards. $DNG is transferred to the address and the lastUpdated field is updated.
    modifier updateReward(address account) {
        uint256 amount = earned(account);
        balanceOf[address(this)] -= amount;

        // won't overflow: sum of all user balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[account] += amount;
        }

        lastUpdated[account] = block.timestamp;
        emit Transfer(address(this), account, amount);
        _;
    }

    // @param account The address which will be staking.
    // @param tokenType The token type to stake.
    // @param amount The amount to stake.
    // note: any unclaimed rewards are updated when a stake occurs (via updateReward)    
    function processStake(
        address account,
        NftType nftType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(nftType)] += amount;
    }

    // @param account The address which will be unstaking.
    // @param tokenType The token type to unstake.
    // @param amount The amount to unstake.
    // note: any unclaimed rewards are updated when an unstake occurs (via updateReward)    
    function processUnstake(
        address account,
        NftType nftType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(nftType)] -= amount;
    }

    /**
     * Process message received from FxChild
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (address from, uint256 token, uint256 count, bool action) = abi.decode(
            message,
            (address, uint256, uint256, bool)
        );
        action
            ? processStake(from, NftType(token), count)
            : processUnstake(from, NftType(token), count);
    }

    // Uses EIP-2612 to give our provider wallet permission to transfer the tokens and pay the gas for the wallet
    // encapsulates permit and transfer in a single transaction. Check out DAI token source code for more ideas
    // note: any unclaimed rewards are withdrawn automatically when a gasless purchase is made (via updateReward)
    function purchaseGasless(
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public updateReward(owner) {
        permit(owner, msg.sender, value, deadline, v, r, s);
        transferFrom(owner, address(this), value);
    }

    // calculate total rewards accumulated for given wallet address
    // based on when that wallet last withdrew rewards versus current block's timestamp.
    function earned(address account) public view returns (uint256) {
        return
            dngPerSecond(account) * (block.timestamp - lastUpdated[account]);
    }

    // calculates current total balance of the user including unclaimed rewards.
    function totalBalance(address account) public view returns (uint256) {
        return balanceOf[account] + earned(account);
    }

    function dngPerSecond(address account) public view returns (uint256) {
        return ((balances[account][0] * rewards.dungeon) +
            (balances[account][1] * rewards.avatar) +
            (balances[account][2] * rewards.quest));
    }


    // allos the contract owner to burn DNG owned by the contract.
    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    // allow the contract owner to airdrop DNG owned by the contract to an array of owners.
    function airdrop(address[] calldata accounts, uint256[] calldata amounts) public onlyOwner {
        require(accounts.length == amounts.length);
        for(uint i = 0; i < accounts.length; i++) {
            uint amount = amounts[i];
            balanceOf[address(this)] -= amount;

        // won't overflow: sum of all user balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[accounts[i]] += amount;
            }

            emit Transfer(address(this), accounts[i], amount);
        }
    }

    // allow the contract owner to mint DNG to the contract.
    function mint(uint256 amount) public onlyOwner {
        _mint(address(this), amount);
    }

    // Withdraw DNG to the requested address.
    // @param recipient The address to withdraw the funds to.
    // @param amount The amount of DNG to withdraw
    function withdrawDng(address recipient, uint256 amount) public onlyOwner {
        balanceOf[address(this)] -= amount;

        // won't overflow: sum of all user balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[recipient] += amount;
        }

        emit Transfer(address(this), recipient, amount);
    }

    // let contract deployer update reward rates for each NFT type.
    function setRewardRates(
        uint256 dungeon,
        uint256 avatar,
        uint256 quest
    ) public onlyOwner {
        rewards.dungeon = dungeon;
        rewards.avatar = avatar;
        rewards.quest = quest;
    }

    function updateFxRootRunnel(address _fxRootTunnel) external onlyOwner {
        fxRootTunnel = _fxRootTunnel;
    }


    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}