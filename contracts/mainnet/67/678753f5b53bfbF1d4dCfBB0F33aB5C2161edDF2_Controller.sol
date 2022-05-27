// SPDX-License-Identifier: MIT

//                                                 ______   __                                                   
//                                                /      \ /  |                                                  
//   _______   ______    ______   _______        /$$$$$$  |$$/  _______    ______   _______    _______   ______  
//  /       | /      \  /      \ /       \       $$ |_ $$/ /  |/       \  /      \ /       \  /       | /      \ 
// /$$$$$$$/ /$$$$$$  |/$$$$$$  |$$$$$$$  |      $$   |    $$ |$$$$$$$  | $$$$$$  |$$$$$$$  |/$$$$$$$/ /$$$$$$  |
// $$ |      $$ |  $$ |$$ |  $$/ $$ |  $$ |      $$$$/     $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$ |      $$    $$ |
// $$ \_____ $$ \__$$ |$$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |/$$$$$$$ |$$ |  $$ |$$ \_____ $$$$$$$$/ 
// $$       |$$    $$/ $$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |$$    $$ |$$ |  $$ |$$       |$$       |
//  $$$$$$$/  $$$$$$/  $$/       $$/   $$/       $$/       $$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$/
//                         .-.
//         .-""`""-.    |(@ @)
//      _/`oOoOoOoOo`\_ \ \-/
//     '.-=-=-=-=-=-=-.' \/ \
//       `-=.=-.-=.=-'    \ /\
//          ^  ^  ^       _H_ \

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IVaultBase.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IPokeMe.sol";
import "./interfaces/IResolver.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IGasTank.sol";


/**
* @title Corn Finance Controller
* @author C.W.B.
*/
contract Controller is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserTokens {
        address vault;
        uint256 tokenId;
    }

    uint8 public constant NOT_A_VAULT = 0;
    uint8 public constant ACTIVE_VAULT = 1;
    uint8 public constant DEACTIVATED_VAULT = 2;

    // Gelato address that receives the gas fee after execution
    address payable public constant gelato = payable(0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA);

    // Native token
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Contract that will call this contract to fill orders
    IPokeMe public PokeMe = IPokeMe(0x527a819db1eb0e34426297b03bae11F2f8B3A19E);

    // Contract for finding the best router and path for a given swap
    IResolver public Resolver;

    // Token used to pay Gelato for executing transactions
    address public GasToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // true: Gelato is active - Gelato will monitor orders and fill when executable
    // false: Gelato is inactive - Dev will monitor orders and fill when executable
    bool public Gelato;

    // taskIds[vaultId][tokenId] --> Gelato task ID
    // Gelato tasks are only created when 'Gelato' = true
    mapping(uint256 => mapping(uint256 => bytes32)) public taskIds;

    // tokenMaxGas[vaultId][tokenId] --> Max gas price (gwei)
    // Filling order txs will revert if the gas price exceeds what the user set
    mapping(uint256 => mapping(uint256 => uint256)) public tokenMaxGas;

    // All routers used for filling orders
    IUniswapV2Router02[] public routers;

    // activeRouters[router] --> true: Router is active; false: Router is inactive
    // Note: Deactivated routers are not removed from 'routers', be sure that the
    // router being used returns 'true' from the mapping below before using to 
    // fill orders.
    mapping(IUniswapV2Router02 => bool) public activeRouters;

    // All vaults
    IVaultBase[] public vaults;

    // _vaults[vault] --> 0: Vault not present in Controller; 1: Vault is active;
    // 2: Vault is deactivated
    mapping(address => uint8) internal _vaults;

    // _vaultIds[vault] --> Vault index of 'vaults' (i.e. vault ID)
    mapping(address => uint256) internal _vaultIds;

    // Dev wallet for protocol fees
    address public constant Fees = 0x93F835b9a2eec7D2E289c1E0D50Ad4dEd88b253f;

    // Community treasury for deposit fees
    address public constant DepositFees = 0xfC484aFB55D9EA9E186D8De55A0Aa24cbe772a19;

    // Slippage setting for when filling orders
    // slippage = SLIPPAGE_POINTS / SLIPPAGE_BASE_POINTS
    // 0.5% slippage --> SLIPPAGE_POINTS = 5; SLIPPAGE_BASE_POINTS = 1000
    uint256 public SLIPPAGE_POINTS;
    uint256 public SLIPPAGE_BASE_POINTS;

    // Contracts that hold trade tokens
    address[] public holdingStrategies;

    // _holdingStrategies[strategy] --> true: Active holding strategy; false: Holding
    // strategy not added yet.
    mapping(address => bool) internal _holdingStrategies;

    IGasTank public GasTank = IGasTank(0xCfbCCC95E48D481128783Fa962a1828f47Fc8A42);


    // --------------------------------------------------------------------------------
    // //////////////////////////////////// Events ////////////////////////////////////
    // --------------------------------------------------------------------------------
    event CreateTrade(address indexed _creator, uint256 indexed _vaultId, uint256 _tokenId);
    event CreateOrder(address indexed _creator, uint256 indexed _vaultId, uint256 _orderId);
    event FillOrder(address indexed _orderOwner, uint256 indexed _vaultId, uint256 indexed _tokenId, uint256 _orderId);
    event Withdraw(address indexed _owner, uint256 indexed _vaultId, uint256 indexed _tokenId);

    
    // --------------------------------------------------------------------------------
    // ////////////////////////////////// Modifiers ///////////////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @dev Restricts the caller to only the Gelato 'PokeMe' contract 
    */
    modifier onlyGelato() {
        require(
            msg.sender == address(PokeMe), 
            "CornFi Controller: Gelato Only Function"
        );
        require(Gelato, "CornFi Controller: Gelato Disabled");
        _;
    }


    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------

    /**
    * @param _slippagePoints: Highest acceptable slippage amount when executing swaps
    * @param _slippageBasePoints: (_slippagePoints / _slippageBasePoints) --> slippage %
    * @param _routers: Approved routers used for executing swaps. No new routers can be
    * added after deploying this contract.
    * @param _resolver: Gelato resolver contract used to find the router and swap path
    * that provides the highest output amount.
    */
    constructor(
        uint256 _slippagePoints,
        uint256 _slippageBasePoints,
        IUniswapV2Router02[] memory _routers,
        address _resolver
    ) {
        _setSlippage(_slippagePoints, _slippageBasePoints);
        Gelato = true;
        
        Resolver = IResolver(_resolver);
        for(uint i = 0; i < _routers.length; i++) {
            _addRouter(_routers[i]);
        }
    }


    // --------------------------------------------------------------------------------
    // //////////////////////// Contract Settings - Only Owner ////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @dev After calling, 'createTrade', 'fillOrder', 'fillOrderGelato', and 'depositGas'
    * functions will be disabled. Users will only be able to withdraw their trades and
    * any deposited gas. Only the owner of this contract can call this function.
    */
    function pause() external onlyOwner {
        _pause();
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Enables 'createTrade', 'fillOrder', 'fillOrderGelato', and 'depositGas'
    * functions. Only the owner of this contract can call this function.
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Set the URI of a vault to display an image. Only the owner of this contract 
    * can call this function.
    * @param _vaultId: Vault that will have its URI set
    * @param _URI: IPFS link
    */
    function setVaultURI(uint256 _vaultId, string memory _URI) external onlyOwner {
        vaults[_vaultId].setBaseURI(_URI);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Add a router to fill orders through
    * @param _router: Uniswap V2 router to add 
    */
    function addRouter(IUniswapV2Router02 _router) external onlyOwner {
        require(!activeRouters[_router], "CornFi Controller: Router already added");
        _addRouter(_router);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Deactivated router will no longer be able to be used for filling orders.
    * Only the owner of this contract can call this function.
    * @param _router: Router to deactivate 
    */
    function deactivateRouter(IUniswapV2Router02 _router) external onlyOwner {
        activeRouters[_router] = false;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Add a vault for trading. Vault must inherit 'VaultBase.sol' and meet the
    * vault standard for proper functionality. Only the owner of this contract can call 
    * this function.
    * @param _vault: Address of vault to add
    */
    function addVault(address _vault) external onlyOwner {
        require(_vaults[_vault] == NOT_A_VAULT);
        _vaultIds[_vault] = vaults.length;
        vaults.push(IVaultBase(_vault));
        _vaults[_vault] = ACTIVE_VAULT;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Disables the 'createTrade', 'fillOrder', and 'fillOrderGelato' functions.
    * Once a vault is deactivated, users will only be able to withdraw their trades.
    * Deactivated vaults cannot be reactivated. Only the owner of this contract can 
    * call this function.
    * @param _vault: Address of vault to deactivate
    */
    function deactivateVault(address _vault) external onlyOwner {
        _vaults[_vault] = DEACTIVATED_VAULT;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Set the slippage amount for each order being filled. Only the owner of this 
    * contract can call this function.
    * @param _slippagePoints: This value divided by '_slippageBasePoints' gives the 
    * slippage percentage.
    * @param _slippageBasePoints: Max amount of slippage points
    */
    function setSlippage(
        uint256 _slippagePoints, 
        uint256 _slippageBasePoints
    ) external onlyOwner {
        _setSlippage(_slippagePoints, _slippageBasePoints);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Configure Gelato settings. Enable/disable filling orders with Gelato. Only 
    * the owner of this contract can call this function.
    * @param _pokeMe: Gelato contract that will call this contract
    * @param _resolver: Contract that the Gelato executor will call for the input data
    * used when calling this contract.
    * @param _gelato: true: Gelato fills orders; false: Dev fills orders
    */
    function gelatoSettings(
        IPokeMe _pokeMe, 
        IResolver _resolver, 
        bool _gelato,
        IGasTank _gasTank
    ) external onlyOwner {
        PokeMe = _pokeMe;
        Resolver = _resolver;
        Gelato = _gelato;
        GasTank = _gasTank;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Deactivate an ERC20 token for a vault. Once a token is deactivated, it cannot
    * be reactivated. Only the owner can call this function.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _token: ERC20 token address  
    */
    function deactivateToken(uint256 _vaultId, address _token) external onlyOwner {
        return vaults[_vaultId].deactivateToken(_token);
    } 

    // --------------------------------------------------------------------------------

    /**
    * @dev Map a holding strategy contract to an ERC20 token. A token can only be mapped
    * to holding strategy once. Only the owner of this contract can call this function.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _token: ERC20 token address
    * @param _strategy: Holding strategy contract
    * @param _minDeposit: Minimum amount of '_token' that can be deposited when creating
    * a trade. 
    */
    function setTokenStrategy(
        uint256 _vaultId, 
        address _token, 
        address _strategy, 
        uint256 _minDeposit
    ) external onlyOwner {
        // Map the holding strategy to the ERC20 token
        vaults[_vaultId].setStrategy(_token, _strategy, _minDeposit);

        // Add the holding strategy address if not already done
        if(!_holdingStrategies[_strategy]) {
            holdingStrategies.push(_strategy);
            _holdingStrategies[_strategy] = true;
        }
    } 

    // --------------------------------------------------------------------------------

    /**
    * @dev Map multiple holding strategies to ERC20 tokens. A token can only be mapped
    * to holding strategy once. Only the owner of this contract can call this function.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _tokens: ERC20 token addresses
    * @param _strategies: Holding strategy contracts
    * @param _minDeposits: Minimum amount of '_tokens[n]' that can be deposited when 
    * creating a trade. 
    */
    function setTokenStrategies(
        uint256 _vaultId, 
        address[] memory _tokens, 
        address[] memory _strategies, 
        uint256[] memory _minDeposits
    ) external onlyOwner {
        require(
            _tokens.length == _strategies.length && _tokens.length == _minDeposits.length, 
            "CornFi Controller: Invalid Lengths"
        );

        for(uint i = 0; i < _tokens.length; i++) {
            // Map the holding strategy to the ERC20 token
            vaults[_vaultId].setStrategy(_tokens[i], _strategies[i], _minDeposits[i]);

            // Add the holding strategy address if not already done
            if(!_holdingStrategies[_strategies[i]]) {
                holdingStrategies.push(_strategies[i]);
                _holdingStrategies[_strategies[i]] = true;
            }
        }
    } 

    // --------------------------------------------------------------------------------

    /**
    * @dev Change the minimum deposit amount for an ERC20 token when creating a trade.
    * ERC20 token must already be mapped to a holding strategy before calling this
    * function. Only the owner of this contract can call this function. 
    */
    function changeTokenMinimumDeposit(
        uint256 _vaultId, 
        address _token, 
        uint256 _minDeposit
    ) external onlyOwner {              
        vaults[_vaultId].changeMinimumDeposit(_token, _minDeposit);
    }


    // --------------------------------------------------------------------------------
    // ///////////////////////////// Read-Only Functions //////////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @notice Use to get the minimum amount out of a swap
    * @param _amountIn: Amount of a given ERC20 token
    * @return Adjusts '_amountIn' to account for slippage
    */
    function slippage(uint256 _amountIn) public view returns (uint256) {
        return _amountIn.sub(_amountIn.mul(SLIPPAGE_POINTS).div(SLIPPAGE_BASE_POINTS));
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _vault: Address of vault
    * @return 0: Not added to this contract; 1 = Active vault; 2 = Deactivated vault
    */
    function vault(address _vault) public view returns (uint8) {
        return _vaults[_vault];
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _vault: Address of vault
    * @return Reverse mapping vault address to index in 'vaults'
    */
    function vaultId(address _vault) public view returns (uint256) {
        return _vaultIds[_vault];
    }

    // --------------------------------------------------------------------------------

    /**
    * @notice Includes active and added then deactivated vaults
    * @return Number of added vaults 
    */
    function vaultsLength() public view returns (uint256) {
        return vaults.length;
    }

    // --------------------------------------------------------------------------------

    /**
    * @notice The prices used when creating trades need to be multiplied by the value
    * returned from this function. This is done to handle the decimals.
    * @param _vaultId: Index of vault in 'vaults'
    * @return Value to multiply with the price 
    */
    function priceMultiplier(uint256 _vaultId) external view returns (uint256) {
        return vaults[_vaultId].PRICE_MULTIPLIER();
    }

    // --------------------------------------------------------------------------------
    // //////////////////////// Vault State Changing Functions ////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @notice Create a trade with one of the approved vaults. The format for '_tokens',
    * '_amounts', and '_times' is specific to the vault. Refer to the vault being used
    * to verify the correct data format. Trades are only created with active vaults.
    * The strating amount of the trade is deposited upon creating a trade. A deposit fee
    * is taken from the deposited amount. When Gelato is active, a task is created for
    * each open order.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _tokens: Specific to the vault used. Refer to vault documentation.
    * @param _amounts: Specific to the vault used. Refer to vault documentation.
    * @param _times: Specific to the vault used. Refer to vault documentation.
    * @param _maxGas: In gwei. The maximum gas price that any order within this trade
    * can be executed at.
    */
    function createTrade(
        uint256 _vaultId, 
        address[] memory _tokens, 
        uint256[] memory _amounts, 
        uint[] memory _times, 
        uint256 _maxGas
    ) external whenNotPaused nonReentrant {
        // Active vaults only
        require(
            vault(address(vaults[_vaultId])) == ACTIVE_VAULT, 
            "CornFi Controller: Inactive Vault"
        );

        // Create a trade and get the created orders 
        uint256[] memory orderIds = vaults[_vaultId].createTrade(
            msg.sender, 
            _tokens, 
            _amounts, 
            _times
        );
        IVaultBase.Order[] memory orders = _viewOrders(_vaultId, orderIds);

        emit CreateTrade(msg.sender, _vaultId, orders[0].tokenId);

        // Max gas price for when filling orders. Lower gas price saves the user ETH,
        // but increases the risk that their orders will not get filled during network
        // congestion.
        tokenMaxGas[_vaultId][orders[0].tokenId] = _maxGas;

        // When Gelato is active, create a task for the orders created. Gelato will monitor
        // each order and execute when trade conditions are met.
        _createGelatoTasks(msg.sender, _vaultId, orders);
    }

    // --------------------------------------------------------------------------------

    /**
    * @notice Fill open orders when trade conditions are met. Only Gelato executors
    * can call this function. This function is the primary method used to fill orders. 
    * If Gelato is no longer used, orders are filled through calling 'fillOrder()'
    * instead. Gelato executor will call 'checker()' in Resolver.sol first to get the 
    * router and path with the highest output amount. Gelato executor is refunded the 
    * gas cost from the ETH the order owner has deposited.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _orderId: Order to fill
    * @param _router: Router used to fill the order
    * @param _path: Swap path used to fill the order
    */
    function fillOrderGelato(
        uint256 _vaultId, 
        uint256 _orderId, 
        IUniswapV2Router02 _router, 
        address[] memory _path
    ) external whenNotPaused onlyGelato nonReentrant {
        // Order to fill
        IVaultBase.Order memory _order = _viewOrder(_vaultId, _orderId);

        _verifyOrder(_router, _vaultId, _order);

        // Fill the order
        (
            IVaultBase.Order[] memory orders, 
            uint256[] memory filledOrders
        ) = vaults[_vaultId].fillOrder(_orderId, _router, _path);

        // Owner of the order being filled
        address orderOwner = vaults[_vaultId].ownerOf(_order.tokenId);

        emit FillOrder(orderOwner, _vaultId, _order.tokenId, _orderId);

        _cancelGelatoTasks(_vaultId, filledOrders);       

        _createGelatoTasks(orderOwner, _vaultId, orders);                                        

        (uint256 fee, ) = PokeMe.getFeeDetails();
        
        GasTank.pay(orderOwner, gelato, fee);
    }

    // --------------------------------------------------------------------------------

    /**
    * @notice Withdraws the ERC20 tokens owned by a vault token and returns to the token
    * owner. All open orders associated with the vault token are closed and the vault
    * token is burnt.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _tokenId: Vault token  
    */
    function withdraw(uint256 _vaultId, uint256 _tokenId) external nonReentrant {
        // Get open orders for the vault token
        IVaultBase.Order[] memory _orders = _viewOpenOrdersByToken(_vaultId, _tokenId);

        // Cancel the tasks with Gelato 
        for(uint i = 0; i < _orders.length; i++) {
            if(taskIds[_vaultId][_orders[i].orderId] != 0) {
                PokeMe.cancelTask(taskIds[_vaultId][_orders[i].orderId]);
            }
        }

        // Withdraw ERC20 tokens and burn vault token
        vaults[_vaultId].withdraw(msg.sender, _tokenId);

        emit Withdraw(msg.sender, _vaultId, _tokenId);
    }


    // --------------------------------------------------------------------------------
    // ////////////////////////////// Internal Functions //////////////////////////////
    // --------------------------------------------------------------------------------    

    /**
    * @dev Whitelists a Uniswap V2 router for filling orders
    * @param _router: Router address
    */
    function _addRouter(IUniswapV2Router02 _router) internal {
        routers.push(_router);
        activeRouters[_router] = true;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Sets the slippage amount used when filling orders
    * @param _slippagePoints: This value divided by '_slippageBasePoints' gives the 
    * slippage percentage.
    * @param _slippageBasePoints: Max amount of slippage points
    */
    function _setSlippage(uint256 _slippagePoints, uint256 _slippageBasePoints) internal {
        // Max slippage allowed is 2%
        require(
            _slippagePoints.mul(50) <= _slippageBasePoints, 
            "CornFi Controller: Max Slippage Exceeded"
        );
        SLIPPAGE_POINTS = _slippagePoints;
        SLIPPAGE_BASE_POINTS = _slippageBasePoints;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Cancels a Gelato task for given orders. Orders cannot get filled after Gelato
    * task is canceled.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _orderIds: List of orders to cancel Gelato tasks for
    */
    function _cancelGelatoTasks(uint256 _vaultId, uint256[] memory _orderIds) internal {
        // If the order has an associated task ID, cancel the task
        for(uint i = 0; i < _orderIds.length; i++) {   
            if(taskIds[_vaultId][_orderIds[i]] != bytes32(0)) { 
                PokeMe.cancelTask(taskIds[_vaultId][_orderIds[i]]);     
            }
        }
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Creates a Gelato task for given orders. Orders can get filled automatically 
    * after Gelato tasks are created.
    * @param _orderOwner: Owner of the orders
    * @param _vaultId: Index of vault in 'vaults'
    * @param _orders: List of orders to create Gelato tasks for
    */
    function _createGelatoTasks(
        address _orderOwner, 
        uint256 _vaultId, 
        IVaultBase.Order[] memory _orders
    ) internal {
        // When using Gelato to fill orders.
        // An order ID greater than '0' indicates a new order was created. Create a new
        // task with Gelato to monitor and fill the created order.
        if(Gelato) {
            for(uint j = 0; j < _orders.length; j++) {                                                          
                if(_orders[j].orderId != 0) {                                                            

                    emit CreateOrder(_orderOwner, _vaultId, _orders[j].orderId);

                    // Create a task with Gelato to monitor and fill the created order
                    taskIds[_vaultId][_orders[j].orderId] = PokeMe.createTaskNoPrepayment(
                        address(this), 
                        this.fillOrderGelato.selector, 
                        address(Resolver), 
                        abi.encodeWithSelector(
                            Resolver.checker.selector, 
                            _vaultId, 
                            _orders[j].orderId, 
                            _orders[j].tokens[0], 
                            _orders[j].tokens[1], 
                            _orders[j].amounts[0]
                        ),
                        GasToken
                    );
                }
            }     
        }             
    }

    // --------------------------------------------------------------------------------
    
    /**
    * @dev Verify an approved router is used to fill the order and ensure transaction
    * gas price is below the user set max.
    * @param _router: Router used to fill orderd
    * @param _vaultId: Index of vault in 'vaults'
    * @param _order: Order to fill
    */
    function _verifyOrder(
        IUniswapV2Router02 _router, 
        uint256 _vaultId, 
        IVaultBase.Order memory _order
    ) internal view {
        // Revert if the router is not whitelisted. 
        require(activeRouters[_router], "CornFi Controller: Invalid Router");

        // When tokenMaxGas = 0, the order can be fill at any gas price.
        // Otherwise, ensure that the gas price is below the user set max.
        if(tokenMaxGas[_vaultId][_order.tokenId] > 0) {
            require(
                tx.gasprice <= tokenMaxGas[_vaultId][_order.tokenId], 
                "CornFi Controller: Gas Price Too High"
            );
        }
    }

    // --------------------------------------------------------------------------------

    /**
    * @notice View a single order. Order can be open or closed.
    * @param _vaultId: Index of vault in 'vaults'
    * @param _orderId: Order to view
    * @return Order details 
    */
    function _viewOrder(
        uint256 _vaultId, 
        uint256 _orderId
    ) internal view returns (IVaultBase.Order memory) {
        return vaults[_vaultId].order(_orderId);
    }

    // --------------------------------------------------------------------------------

    /**
    * @notice View multiple orders. 
    * @param _vaultId: Index of vault in 'vaults'
    * @param _orderIds: Orders to view
    * @return Array of order details 
    */
    function _viewOrders(
        uint256 _vaultId, 
        uint256[] memory _orderIds
    ) internal view returns (IVaultBase.Order[] memory) {
        IVaultBase _vault = vaults[_vaultId];
        IVaultBase.Order[] memory _orders = new IVaultBase.Order[](_orderIds.length);

        // Loop through orders
        for(uint i = 0; i < _orderIds.length; i++) {
            _orders[i] = _vault.order(_orderIds[i]);
        }
        return _orders;
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _vaultId: Index of vault in 'vaults'
    * @param _tokenId: Vault token
    * @return All open orders for a given vault token
    */ 
    function _viewOpenOrdersByToken(
        uint256 _vaultId, 
        uint256 _tokenId
    ) internal view returns (IVaultBase.Order[] memory) {
        IVaultBase _vault = vaults[_vaultId];

        // Get number of open orders for a vault token
        uint256 orderLength = _vault.tokenOpenOrdersLength(_tokenId);

        IVaultBase.Order[] memory _orders = new IVaultBase.Order[](orderLength);

        // Loop through open orders
        for(uint i = 0; i < orderLength; i++) {
            _orders[i] = _vault.order(_vault.tokenOpenOrderId(_tokenId, i));
        }
        return _orders;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";
import "./IStrategy.sol";

pragma experimental ABIEncoderV2;

interface IVaultBase {
    struct Order {
        uint256 tokenId;
        uint256 tradeId;
        uint256 orderId;
        uint timestamp;
        address[2] tokens;
        uint256[3] amounts;
        uint[] times;
    }

    struct Strategy {
        address[] tokens;
        uint256[] amounts;
        uint[] times;
    }

    struct Token {
        address token;
        uint256 amount;
    }

    function tokenCounter() external view returns (uint256);
    function maxTokens() external view returns (uint256);
    function owner() external view returns (address);
    function _tokenTradeLength(uint256 _tokenId) external view returns (uint256);
    function setStrategy(address _token, address _strategy, uint256 _minDeposit) external;
    function changeMinimumDeposit(address _token, uint256 _minDeposit) external;
    function strategy(address _token) external view returns (IStrategy);
    function minimumDeposit(address _token) external view returns (uint256);

    function trade(uint256 _tokenId, uint256 _tradeId) external view returns (uint256[] memory);
    function order(uint256 _orderId) external view returns (Order memory);
    function ordersLength() external view returns (uint256);
    function openOrdersLength() external view returns (uint256);
    function openOrderId(uint256 _index) external view returns (uint256);
    function tokenOpenOrdersLength(uint256 _tokenId) external view returns (uint256);
    function tokenOpenOrderId(uint256 _tokenId, uint256 _index) external view returns (uint256);
    function viewTokenAmounts(uint256 _tokenId) external view returns (Token[] memory);
    function viewStrategy(uint256 _tokenId) external view returns (Strategy memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function createTrade(address _from, address[] memory _tokens, uint256[] memory _amounts, uint[] memory _times) external returns (uint256[] memory);
    function fillOrder(uint256 _orderId, IUniswapV2Router02 _router, address[] memory _path) external returns (Order[] memory, uint256[] memory);
    function withdraw(address _from, uint256 _tokenId) external;

    function balanceOf(address _owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokens(uint256 _index) external view returns (address);
    function tokensLength() external view returns (uint256);
    function deactivateToken(address _token) external;
    function activeTokens(address _token) external view returns (bool);

    function setBaseURI(string memory) external;
    function BASE_URI() external view returns (string memory);
    function PRICE_MULTIPLIER() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


interface IPokeMe {
    function gelato() external view returns (address payable);
    
    function createTimedTask(
        uint128 _startTime,
        uint128 _interval,
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken,
        bool _useTreasury
    ) external returns (bytes32 task);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    function cancelTask(bytes32 _taskId) external;

    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external ;

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector,
        bool _useTaskTreasuryFunds,
        address _feeToken,
        bytes32 _resolverHash
    ) external pure returns (bytes32);

    function getSelector(string calldata _func) external pure returns (bytes4);
    
    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function getFeeDetails() external view returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";


interface IResolver {
    function checker(
        uint256 _vaultId, 
        uint256 _orderId, 
        address _fromToken, 
        address _toToken, 
        uint256 _fromAmount
    ) external view returns (bool, bytes memory);

    function findBestPathExactIn(
        address _fromToken, 
        address _toToken, 
        uint256 _amountIn
    ) external view returns (address, address[] memory, uint256);

    function findBestPathExactOut(
        address _fromToken, 
        address _toToken, 
        uint256 _amountOut
    ) external view returns (address, address[] memory, uint256);

    function getAmountOut(
        IUniswapV2Router02 _router, 
        uint256 _amountIn, 
        address _fromToken, 
        address _connectorToken, 
        address _toToken
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


pragma experimental ABIEncoderV2;

interface IStrategy {
    struct Tokens {
        address token;
        address amToken;
    }

    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event TokenAdded(address token, address amToken);


    function depositFee(uint256 _amountIn) external view returns (uint256);
    function txFee(uint256 _amountIn) external view returns (uint256);
    function fillerFee(uint256 _amountIn) external view returns (uint256);
    function deposit(address _from, address _token, uint256 _amount) external;
    function withdraw(address _from, address _token, uint256 _amount) external;
    function vaultDeposits(address _vault, address _token) external view returns (uint256);

    function DEPOSIT_FEE_POINTS() external view returns (uint256);
    function DEPOSIT_FEE_BASE_POINTS() external view returns (uint256);
    function TX_FEE_POINTS() external view returns (uint256);
    function TX_FEE_BASE_POINTS() external view returns (uint256);
    function rebalanceToken(address _token) external;
    function claim() external;
    function balanceRatio(address _token) external view returns (uint256, uint256);
    function rebalancePoints() external view returns (uint256);
    function rebalanceBasePoints() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IGasTank {
    event DepositGas(address indexed user, uint256 amount);
    event WithdrawGas(address indexed user, uint256 amount);
    event Pay(address indexed payer, address indexed payee, uint256 amount);
    event Approved(address indexed payer, address indexed payee, bool approved);

    // View
    function userGasAmounts(address _user) external view returns (uint256);
    function approvedPayees(uint256 _index) external view returns (address);
    function _approvedPayees(address _payee) external view returns (bool);
    function userPayeeApprovals(address _payer, address _payee) external view returns (bool);
    function txFee() external view returns (uint256);
    function feeAddress() external view returns (address);
    
    // Users
    function depositGas(address _receiver) external payable;
    function withdrawGas(uint256 _amount) external;
    function approve(address _payee, bool _approve) external;
    
    // Approved payees
    function pay(address _payer, address _payee, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

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