// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "../interfaces/IHedgepieAuthority.sol";

abstract contract HedgepieAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IHedgepieAuthority indexed authority);

    // unauthorized error message
    string private _unauthorized = "UNAUTHORIZED"; // save gas

    // paused error message
    string private _paused = "PAUSED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IHedgepieAuthority public authority;

    /* ========== Constructor ========== */
    /**
     * @notice Constructor
     * @param _authority address of authority
     */
    constructor(IHedgepieAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier whenNotPaused() {
        require(!authority.paused(), _paused);
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), _unauthorized);
        _;
    }

    modifier onlyPathManager() {
        require(msg.sender == authority.pathManager(), _unauthorized);
        _;
    }

    modifier onlyAdapterManager() {
        require(msg.sender == authority.adapterManager(), _unauthorized);
        _;
    }

    modifier onlyInvestor() {
        require(msg.sender == authority.hInvestor(), _unauthorized);
        _;
    }

    /* ========== GOV ONLY ========== */
    /**
     * @notice Set new authority
     * @param _newAuthority address of new authority
     */
    /// #if_succeeds {:msg "setAuthority failed"}  authority == _newAuthority;
    function setAuthority(IHedgepieAuthority _newAuthority) external onlyGovernor {
        require(address(_newAuthority) != address(0), "Invalid adddress");
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./HedgepieAccessControlled.sol";
import "../interfaces/IHedgepieAuthority.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakeRouter.sol";

contract PathFinder is HedgepieAccessControlled {
    // router information
    mapping(address => bool) public routers;

    // router => inToken => outToken => path
    mapping(address => mapping(address => mapping(address => address[]))) public paths;

    /// @dev events
    event RouterAdded(address indexed router, bool status);
    event RouterRemoved(address indexed router, bool status);

    /**
     * @notice Construct
     * @param _hedgepieAuthority HedgepieAuthority address
     */
    constructor(address _hedgepieAuthority) HedgepieAccessControlled(IHedgepieAuthority(_hedgepieAuthority)) {}

    /**
     * @notice Set swap router
     * @param _router swap router address
     * @param _status router status flag
     */
    /// #if_succeeds {:msg "setRouter does not update the routers"}  routers[_router] == _status;
    function setRouter(address _router, bool _status) external onlyPathManager {
        require(_router != address(0), "Invalid router address");
        routers[_router] = _status;

        if (_status) emit RouterAdded(_router, _status);
        else emit RouterRemoved(_router, _status);
    }

    /**
     * @notice Get path
     * @param _router router address
     * @param _inToken token address of inToken
     * @param _outToken token address of outToken
     */
    function getPaths(address _router, address _inToken, address _outToken) public view returns (address[] memory) {
        require(paths[_router][_inToken][_outToken].length > 1, "Path not existing");

        return paths[_router][_inToken][_outToken];
    }

    /**
     * @notice Set path from inToken to outToken
     * @param _router swap router address
     * @param _inToken token address of inToken
     * @param _outToken token address of outToken
     * @param _path swapping path
     */
    /// #if_succeeds {:msg "setPath does not update the path"}  paths[_router][_inToken][_outToken].length == _path.length;
    function setPath(
        address _router,
        address _inToken,
        address _outToken,
        address[] memory _path
    ) external onlyPathManager {
        require(routers[_router], "Router not registered");
        require(_path.length > 1, "Invalid path length");
        require(_inToken == _path[0], "Invalid inToken address");
        require(_outToken == _path[_path.length - 1], "Invalid inToken address");

        IPancakeFactory factory = IPancakeFactory(IPancakeRouter(_router).factory());
        address[] storage cPath = paths[_router][_inToken][_outToken];

        uint8 i;
        for (i; i < _path.length; i++) {
            // check if new path is valid
            if (i < _path.length - 1) require(factory.getPair(_path[i], _path[i + 1]) != address(0), "Invalid path");

            // update current path if new path is valid
            if (i < cPath.length) cPath[i] = _path[i];
            else cPath.push(_path[i]);
        }

        uint256 cPathLength = cPath.length;
        // remove deprecated path token info after new path is updated
        if (cPathLength > _path.length) {
            for (i = 0; i < cPathLength - _path.length; i++) cPath.pop();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

interface IHedgepieAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PathManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event AdapterManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event PathManagerPulled(address indexed from, address indexed to);
    event AdapterManagerPulled(address indexed from, address indexed to);

    event HInvestorUpdated(address indexed from, address indexed to);
    event HYBNFTUpdated(address indexed from, address indexed to);
    event HAdapterListUpdated(address indexed from, address indexed to);
    event PathFinderUpdated(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function pathManager() external view returns (address);

    function adapterManager() external view returns (address);

    function hInvestor() external view returns (address);

    function hYBNFT() external view returns (address);

    function hAdapterList() external view returns (address);

    function pathFinder() external view returns (address);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPancakeRouter {
    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    function factory() external view returns (address);
}