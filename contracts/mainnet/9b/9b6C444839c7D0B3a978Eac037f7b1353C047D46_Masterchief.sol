// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/HalfLife.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/IToken.sol";

interface IController {
    function rebalance(int256 amount) external;
}

contract Masterchief is ReentrancyGuard {
    address public immutable timelock;

    address public governor;
    address public creator;
    address public deputy;

    uint256 public denominator;
    uint256 public halfLife;
    uint256 public sellTaxPermille;
    uint256[2] public rebalancePermille;

    IPair public pair;
    IRouter public router;

    IToken public token;
    IGovernanceToken public governanceToken;

    uint256 private decayLatest;
    uint256 private constant HALFLIFE_SECONDS_MIN = 2592000;

    address[][] private paths;
    address[] private controllers;

    struct Controller {
        uint256 numerator;
        uint256 tokenAmountClaimed;
        uint256 tokenAmountUnclaimed;
    }

    struct ControllerExtended {
        address controller;
        uint256 numerator;
        uint256 tokenAmountClaimed;
        uint256 tokenAmountUnclaimed;
    }

    struct Shareholder {
        uint256 createdAt;
        uint256 totalClaims;
        uint256 tokenAmountClaimed;
    }

    struct ShareholderExtended {
        address controller;
        address account;
        uint256 createdAt;
        uint256 delay;
        uint256 share;
        uint256 shares;
        uint256 totalClaims;
        uint256 tokenAmountClaimed;
        uint256 tokenAmountUnclaimed;
        bytes params;
    }

    mapping (address => Controller) private controller;
    mapping (address => mapping (address => Shareholder)) private shareholder;
    mapping (address => address[]) private shareholderAccounts;
    mapping (address => mapping (bytes4 => bool)) private selector;
    mapping (bytes4 => bool) private deputySelector;

    event Claimed(
        address indexed controller,
        address indexed account,
        address indexed recipient,
        uint256 delay,
        uint256 share,
        uint256 shares,
        uint256 pathId,
        uint256[] amounts
    );

    constructor(
        IRouter router_,
        address timelock_
    )
    {
        router = router_;
        timelock = timelock_;

        creator = msg.sender;
        deputy = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyTimelock {
        require(timelock == msg.sender); _;
    }

    modifier onlyController {
        require(
            controller[msg.sender].numerator > 0 ||
            controllers.length == 0
        ); _;
    }

    function sync()
        external
        nonReentrant
    {
        _sync(0, 0);
    }

    function buy(
        address recipient,
        address delegatee,
        uint256 pathId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline
    )
        external
        nonReentrant
        payable
    {
        require(sellTaxPermille > 0);

        _swapForGovernanceToken(
            pathId,
            amount,
            amountOutMin,
            deadline,
            recipient,
            delegatee
        );
    }

    function sell(
        address recipient,
        address delegatee,
        uint256 pathId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline
    )
        external
        nonReentrant
    {
        _swapGovernanceTokenFor(
            pathId,
            amount,
            amountOutMin,
            deadline,
            recipient,
            delegatee,
            msg.sender
        );
    }

    function claim(
        address ref,
        address account,
        address recipient,
        uint256 blockNumber,
        uint256 delay,
        uint256 share,
        uint256 shares,
        uint256 pathId,
        uint256 amountOutMin
    )
        external
        nonReentrant
        onlyController
        returns (uint256[] memory)
    {
        uint256[] memory amounts;
        address controller_ = msg.sender;

        uint256 tokenAmountUnclaimed = unclaimed(
            controller_,
            ref,
            blockNumber,
            delay,
            share,
            shares
        );

        shareholder[controller_][account].totalClaims++;

        if(tokenAmountUnclaimed == 0) return amounts;

        controller[controller_].tokenAmountUnclaimed -= tokenAmountUnclaimed;
        controller[controller_].tokenAmountClaimed += tokenAmountUnclaimed;

        if(ref != account) shareholder[controller_][ref].tokenAmountClaimed += tokenAmountUnclaimed;

        shareholder[controller_][account].tokenAmountClaimed += tokenAmountUnclaimed;

        if(pathId == 0) {
            require(tokenAmountUnclaimed >= amountOutMin);

            _transfer(paths[0][0], recipient, tokenAmountUnclaimed);

            amounts = new uint256[](1);
            amounts[0] = tokenAmountUnclaimed;
            _sync(0, 0);
        } else if(pathId == 2) {
            amounts = router.swapExactTokensForETH(
                tokenAmountUnclaimed,
                amountOutMin,
                paths[pathId],
                recipient,
                block.timestamp
            );
            _sync(amounts[0], 0);
        } else {
            amounts = router.swapExactTokensForTokens(
                tokenAmountUnclaimed,
                amountOutMin,
                paths[pathId],
                recipient,
                block.timestamp
            );
            _sync(amounts[0], 0);
        }

        emit Claimed(controller_, account, recipient, delay, share, shares, pathId, amounts);

        return amounts;
    }

    function swapToken(
        address recipient,
        uint256 pathId,
        uint256 amountOutMin,
        uint256 amountInMax,
        uint256 deadline,

        address controller_,
        bytes4 selector_,
        bytes calldata args
    )
        external
        nonReentrant
        payable
    {
        bool success;
        if(recipient == address(0)) { // buy
            _swapForToken(
                pathId,
                amountOutMin,
                amountInMax,
                deadline
            );
            _transfer(paths[0][0], controller_, amountOutMin);
            (success, ) = controller_.call(abi.encodeWithSelector(
                selector_,
                args,
                msg.sender,
                amountOutMin,
                0
            ));
        } else { // sell
            bytes memory result;
            (success, result) = controller_.call(abi.encodeWithSelector(
                selector_,
                args,
                msg.sender,
                0
            ));
            _swapTokenFor(
                pathId,
                abi.decode(result, (uint256)),
                amountOutMin,
                deadline,
                recipient
            );
        }

        _swapIsValid(controller_, selector_, success);
    }

    function swapGovernanceToken(
        address recipient,
        uint256 pathId,
        uint256 amountOutMin,
        uint256 amountIn,
        uint256 deadline,

        address controller_,
        bytes4 selector_,
        bytes calldata args
    )
        external
        nonReentrant
        payable
    {
        bool success;
        if(recipient == address(0)) { // buy
            _swapForGovernanceToken(
                pathId,
                amountIn,
                amountOutMin,
                deadline,
                controller_,
                controller_
            );
            (success, ) = controller_.call(abi.encodeWithSelector(
                selector_,
                args,
                msg.sender,
                amountOutMin,
                1
            ));
        } else { // sell
            bytes memory result;
            (success, result) = controller_.call(abi.encodeWithSelector(
                selector_,
                args,
                msg.sender,
                1
            ));
            _swapGovernanceTokenFor(
                pathId,
                abi.decode(result, (uint256)),
                amountOutMin,
                deadline,
                address(0),
                address(0),
                address(this)
            );
        }

        _swapIsValid(controller_, selector_, success);
    }

    function initShareholder(
        address account
    )
        external
        onlyController
    {
        address controller_ = msg.sender;
        if(
            account != address(0) &&
            account != address(this) &&
            shareholder[controller_][account].createdAt == 0
        ) {
            shareholder[controller_][account].createdAt = block.timestamp;
            shareholderAccounts[controller_].push(account);
        }
    }

    function swapTokenFor(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient
    )
        external
        onlyController
        nonReentrant
    {
        _swapTokenFor(
            pathId,
            amountIn,
            amountOutMin,
            deadline,
            recipient
        );
    }

    function swapGovernanceTokenFor(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient,
        address delegatee
    )
        external
        onlyController
        nonReentrant
    {
        _swapGovernanceTokenFor(
            pathId,
            amountIn,
            amountOutMin,
            deadline,
            recipient,
            delegatee,
            address(this)
        );
    }

    function isController(
        address controller_
    )
        external
        view
        returns(bool)
    {
        return (controller[controller_].numerator > 0);
    }

    function controllerAddressBatch()
        external
        view
        returns(address[] memory)
    {
        return controllers;
    }

    function controllerBatch()
        external
        view
        returns(ControllerExtended[] memory)
    {
        ControllerExtended[] memory controllers_ = new ControllerExtended[](controllers.length);
        Controller memory controller_;
        for (uint256 i = 0; i < controllers.length; i++) {
            controller_ = controller[controllers[i]];
            controllers_[i] = ControllerExtended({
                controller: controllers[i],
                numerator: controller_.numerator,
                tokenAmountClaimed: controller_.tokenAmountClaimed,
                tokenAmountUnclaimed: controller_.tokenAmountUnclaimed
            });
        }
        return controllers_;
    }

    function pathBatch()
        external
        view
        returns(address[][] memory)
    {
        return paths;
    }

    function totalShareholders()
        external
        view
        returns(uint256)
    {
        return shareholderAccounts[msg.sender].length;
    }

    function shareholderAccountBatch(
        uint256 skip,
        uint256 total
    )
        external
        view
        returns(address[] memory)
    {
        address controller_ = msg.sender;
        total = (total == 0) ? shareholderAccounts[controller_].length - skip : total;
        address[] memory shareholderAccounts_ = new address[](total);
        uint256 c;
        for (uint256 i = skip; i < (skip + total); i++) {
            shareholderAccounts_[c] = shareholderAccounts[controller_][i];
            c++;
        }
        return shareholderAccounts_;
    }

    function shareholderExtended(
        address account,
        uint256 blockNumber,
        uint256 delay,
        uint256 share,
        uint256 shares,
        bytes calldata params
    )
        public
        view
        returns (ShareholderExtended memory)
    {
        Shareholder memory shareholder_ = shareholder[msg.sender][account];
        return ShareholderExtended({
            controller: msg.sender,
            account: account,
            createdAt: shareholder_.createdAt,
            delay: delay,
            share: share,
            shares: shares,
            totalClaims: shareholder_.totalClaims,
            tokenAmountClaimed: shareholder_.tokenAmountClaimed,
            tokenAmountUnclaimed: unclaimed(msg.sender, account, blockNumber, delay, share, shares),
            params: params
        });
    }

    function shareholderExtendedBatch(
        address[] calldata accounts,
        uint256[] calldata blockNumbers,
        uint256[] calldata delays,
        uint256[] calldata shares,
        bytes[] calldata params,
        uint256 shares_
    )
        external
        view
        returns (ShareholderExtended[] memory)
    {
        ShareholderExtended[] memory shareholders_ = new ShareholderExtended[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            shareholders_[i] = shareholderExtended(
                accounts[i],
                blockNumbers[i],
                delays[i],
                shares[i],
                shares_,
                params[i]
            );
        }
        return shareholders_;
    }

    function unclaimed(
        address controller_,
        address ref,
        uint256 blockNumber,
        uint256 delay,
        uint256 share,
        uint256 shares
    )
        public
        view
        returns (uint256)
    {
        if(blockNumber + delay > block.number || shares == 0 || blockNumber == 0) return 0;

        uint256 tokenAmountUnclaimed = (
            controller[controller_].tokenAmountUnclaimed + controller[controller_].tokenAmountClaimed
        ) * share / shares;

        if(shareholder[controller_][ref].tokenAmountClaimed >= tokenAmountUnclaimed) return 0;
        tokenAmountUnclaimed -= shareholder[controller_][ref].tokenAmountClaimed;

        if(controller[controller_].tokenAmountUnclaimed < tokenAmountUnclaimed) return 0;
        return tokenAmountUnclaimed;
    }

    function isDeputySelector(
        bytes4 selector_
    )
        external
        view
        returns(bool)
    {
        return deputySelector[selector_];
    }

    function _swapForGovernanceToken(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient,
        address delegatee
    )
        internal
    {
        _addLiquidity(
            recipient,
            delegatee,
            _swapForUSDC(
                pathId,
                amountIn,
                0,
                deadline,
                address(this)
            ),
            amountOutMin,
            deadline
        );
    }

    function _swapGovernanceTokenFor(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient,
        address delegatee,
        address sender
    )
        internal
    {
        _swapUSDCFor(
            pathId,
            _removeLiquidity(
                recipient,
                delegatee,
                sender,
                amountIn,
                deadline
            ),
            amountOutMin,
            deadline,
            recipient
        );
    }

    function _swapForUSDC(
        uint256 pathId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient
    )
        internal
        returns (uint256)
    {
        if(pathId == 1) {
            _transferFrom(paths[1][1], msg.sender, recipient, amount);
        } else if(pathId == 2 && msg.value > 0) {
            address[] memory path = new address[](2);
            path[0] = paths[2][2]; path[1] = paths[2][1];
            amount = router.swapExactETHForTokens{ value: msg.value }(
                amountOutMin,
                path,
                recipient,
                deadline
            )[1];
        } else if(pathId == 0) {
            _transferFrom(paths[1][0], msg.sender, address(this), amount);
            amount = router.swapExactTokensForTokens(
                amount,
                amountOutMin,
                paths[1],
                recipient,
                deadline
            )[1];
        } else {
            address[] memory path = new address[](paths[pathId].length - 1);
            for (uint256 i = 1; i <= path.length; i++) path[i - 1] = paths[pathId][paths[pathId].length - i];
            _transferFrom(path[0], msg.sender, address(this), amount);
            amount = router.swapExactTokensForTokens(
                amount,
                amountOutMin,
                path,
                recipient,
                deadline
            )[path.length - 1];
        }

        return amount;
    }

    function _swapForToken(
        uint256 pathId,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 deadline
    )
        internal
    {
        if(pathId == 0) {
            _transferFrom(paths[0][0], msg.sender, address(this), amountOut);
            return;
        }

        address[] memory path = new address[](paths[pathId].length);
        for (uint256 i = 0; i < path.length; i++) path[i] = paths[pathId][paths[pathId].length - i - 1];

        if(pathId == 2 && msg.value > 0) {
            router.swapETHForExactTokens{ value: msg.value }(
                amountOut,
                path,
                address(this),
                deadline
            );
        } else {
            _transferFrom(path[0], msg.sender, address(this), amountInMax);
            uint256 amount0 = router.swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                address(this),
                deadline
            )[0];
            _transfer(path[0], msg.sender, amountInMax - amount0);
        }
    }

    function _swapTokenFor(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient
    )
        internal
    {
        if(pathId == 2) {
            router.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                paths[pathId],
                recipient,
                deadline
            );
        } else {
            router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                paths[pathId],
                recipient,
                deadline
            );
        }

        _sync(amountIn, 1);
    }

    function _swapUSDCFor(
        uint256 pathId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address recipient
    )
        internal
    {
        require(pathId != 0);
        if(pathId == 1) {
            require(amountIn >= amountOutMin);
            _transfer(paths[1][1], recipient, amountIn);
        } else if(pathId == 2) {
            address[] memory path = new address[](2);
            path[0] = paths[2][1]; path[1] = paths[2][2];
            router.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                recipient,
                deadline
            );
        } else {
            address[] memory path = new address[](paths[pathId].length - 1);
            for (uint256 i = 1; i <= path.length; i++) path[i - 1] = paths[pathId][i];
            router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                recipient,
                deadline
            );
        }
    }

    function _swapIsValid(
        address controller_,
        bytes4 selector_,
        bool success
    )
        internal
        view
    {
        require(
            controller[controller_].numerator > 0 &&
            selector[controller_][selector_] &&
            success
        );
    }

    function _sync(
        uint256 amount,
        uint256 index
    )
        internal
    {
        if(sellTaxPermille == 0) return;

        token.sync(address(pair), amount);
        pair.sync();

        address masterchief_ = address(this);

        if(amount > 0 && rebalancePermille[index] > 0) {
            token.rebalance(-int256(amount * rebalancePermille[index] / 1000), masterchief_);
        }

        uint256 balance = _balance();
        uint256 delta;
        for (uint256 i = 0; i < controllers.length; i++) {
            delta += controller[controllers[i]].tokenAmountUnclaimed;
        }
        uint256 numerator;
        if(balance > delta) {
            delta = balance - delta;
            for (uint256 i = 0; i < controllers.length; i++) {
                numerator = controller[controllers[i]].numerator;
                if(numerator > 1) {
                    controller[controllers[i]].tokenAmountUnclaimed += delta *
                        numerator / denominator;
                }
            }
        } else if(balance < delta) {
            delta = delta - balance;
            for (uint256 i = 0; i < controllers.length; i++) {
                numerator = controller[controllers[i]].numerator;
                if(numerator > 1) {
                    controller[controllers[i]].tokenAmountUnclaimed -= delta *
                        numerator / denominator;
                }
            }
        }

        if(halfLife == 0) return;

        uint256 liquidity = pair.balanceOf(masterchief_);
        uint256 remaining = HalfLife.remaining(
            halfLife,
            block.timestamp - decayLatest,
            liquidity
        );

        delta = liquidity - remaining;
        if(delta < 100000) return;

        decayLatest = block.timestamp;

        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            paths[1][0],
            paths[1][1],
            delta,
            0,
            0,
            masterchief_,
            block.timestamp
        );

        address[] memory path = new address[](2);
        path[0] = paths[1][1]; path[1] = paths[1][0];
        amount0 += router.swapExactTokensForTokens(
            amount1,
            0,
            path,
            masterchief_,
            block.timestamp
        )[1];

        token.rebalance(-int256(amount0), masterchief_);
    }

    function _addLiquidity(
        address recipient,
        address delegatee,
        uint256 amount1,
        uint256 amountOutMin,
        uint256 deadline
    )
        internal
    {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        if(pair.token0() == paths[1][1]) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }

        uint256 amount0 = amount1 * reserve0 / reserve1;

        token.rebalance(int256(amount0), address(this));
        for (uint256 i = 1; i < controllers.length; i++) {
            IController(controllers[i]).rebalance(int256(amount0));
        }

        uint256 liquidity = pair.balanceOf(address(this));
        (, , uint256 liquidity_) = router.addLiquidity(
            paths[1][0],
            paths[1][1],
            amount0,
            amount1,
            0,
            0,
            address(this),
            deadline
        );

        uint256 circulatingSupply = governanceToken.circulatingSupply();
        uint256 amountGovernanceToken = circulatingSupply *
            (liquidity + liquidity_) / liquidity -
            circulatingSupply;

        require(amountGovernanceToken >= amountOutMin);

        governanceToken.rebalance(int256(amountGovernanceToken), msg.sender, recipient, delegatee);

        governanceToken.transfer(recipient, amountGovernanceToken);
    }

    function _removeLiquidity(
        address recipient,
        address delegatee,
        address sender,
        uint256 amount,
        uint256 deadline
    )
        internal
        returns (uint256)
    {
        uint256 lp = pair.balanceOf(address(this))
            * amount
            * (1000 - ((sender == address(this)) ? 0 : sellTaxPermille))
            / (governanceToken.circulatingSupply() * 1000);

        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            paths[1][0],
            paths[1][1],
            lp,
            0,
            0,
            address(this),
            deadline
        );

        token.rebalance(-int256(amount0), address(this));
        for (uint256 i = 1; i < controllers.length; i++) {
            IController(controllers[i]).rebalance(-int256(amount0));
        }

        if(sender != address(this)) governanceToken.transferFrom(sender, address(this), amount);

        governanceToken.rebalance(-int256(amount), sender, recipient, delegatee);

        return amount1;
    }

    function init(
        address governor_,
        IGovernanceToken governanceToken_,
        address deputy_
    )
        external
        onlyTimelock
    {
        require(governor == address(0));

        governor = governor_;
        governanceToken = governanceToken_;
        deputy = deputy_;

        approve();
    }

    function approve()
        public
    {
        for (uint256 i = 0; i < paths.length; i++) {
            _approve(paths[i][paths[i].length - 1]);
        }

        if(paths.length > 1) {
            pair = IPair(IRouter(router.factory()).getPair(paths[1][0], paths[1][1]));
            _approve(address(pair));
        }

        _approve(address(governanceToken));
    }

    function setControllerBatch(
        address[] calldata controllers_,
        uint256[] calldata numerators,
        bytes4[][] calldata selectors_,
        bool[][] calldata selectorsAllowed,
        int256[] calldata tokenAmounts
    )
        external
        onlyTimelock
    {
        require(controllers_[0] == governor);

        for (uint256 i = 0; i < controllers_.length; i++) {
            controller[controllers_[i]].numerator = 0;
        }

        controllers = new address[](0);
        denominator = 0;

        address controller_;
        for (uint256 i = 0; i < controllers_.length; i++) {
            controller_ = controllers_[i];

            controllers.push(controller_);
            controller[controller_].numerator = numerators[i];

            denominator += numerators[i];

            for (uint256 y = 0; y < selectors_[i].length; y++) {
                selector[controller_][selectors_[i][y]] = selectorsAllowed[i][y];
            }

            if(tokenAmounts[i] != 0) token.rebalance(tokenAmounts[i], controller_);
        }
    }

    function setHalfLife(
        uint256 halfLife_
    )
        external
        onlyTimelock
    {
        require(halfLife_ >= HALFLIFE_SECONDS_MIN);

        decayLatest = block.timestamp;
        halfLife = halfLife_;
    }

    function setCreator(
        address creator_
    )
        external
        onlyTimelock
    {
        require(creator_ != address(0));
        creator = creator_;
    }

    function setDeputy(
        address deputy_
    )
        external
        onlyTimelock
    {
        deputy = deputy_;
    }

    function setDeputySelector(
        bytes4 selector_,
        bool value
    )
        external
        onlyTimelock
    {
        deputySelector[selector_] = value;
    }

    function addPath(
        address[] calldata path
    )
        external
        onlyTimelock
    {
        paths.push(path);
        if(paths.length == 1) {
            token = IToken(paths[0][0]);
        } else if(paths.length > 1) {
            require(
                paths[paths.length - 1][0] == paths[1][0] &&
                paths[paths.length - 1][1] == paths[1][1]
            );
        }
    }

    function setRouter(
        IRouter router_
    )
        external
        onlyTimelock
    {
        require(address(router) != address(router_));
        _migrateRouter(router_);
    }

    function setSellTaxPermille(
        uint256 sellTaxPermille_
    )
        external
        onlyTimelock
    {
        require(sellTaxPermille_ <= 1000 && sellTaxPermille_ >= 50);
        sellTaxPermille = sellTaxPermille_;
    }

    function setRebalancePermille(
        uint256[2] memory rebalancePermille_
    )
        external
        onlyTimelock
    {
        require(rebalancePermille_[0] <= 1000 && rebalancePermille_[1] <= 1000);
        rebalancePermille = rebalancePermille_;
    }

    function setMasterchief(
        Masterchief masterchief_
    )
        external
        onlyTimelock
    {
        address _masterchief_ = address(masterchief_);
        require(
            address(this) != _masterchief_ &&
            masterchief_.timelock() == msg.sender
        );
        _transfer(address(pair), _masterchief_, pair.balanceOf(address(this)));
        _transfer(paths[0][0], _masterchief_, _balance());
        masterchief_.sync();
    }

    function _balance()
        internal
        view
        returns (uint256)
    {
        return token.balanceOf(address(this));
    }

    function _transfer(
        address path,
        address to,
        uint256 amount
    )
        internal
    {
        IToken(path).transfer(to, amount);
    }

    function _transferFrom(
        address path,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        IToken(path).transferFrom(from, to, amount);
    }

    function _migrateRouter(
        IRouter router_
    )
        internal
    {
        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            paths[1][0],
            paths[1][1],
            pair.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        router = router_;

        approve();

        router.addLiquidity(
            paths[1][0],
            paths[1][1],
            amount0,
            amount1,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _approve(
        address token_
    )
        internal
    {
        IToken _token_ = IToken(token_);
        address router_ = address(router);
        _token_.approve(router_, 0);
        _token_.approve(router_, type(uint256).max);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library HalfLife {
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  int128 private constant N0i = 18446744073709551616000000000000000000;
  int128 private constant LN2i = 12786308645202655659;
  uint256 private constant N0u = 10**18;

  function remaining(
      uint hl,
      uint t,
      uint x
  )
      external
      pure
      returns (uint)
  {
      return mulu(mul(N0i, inv(exp(div(mul(fromUInt(t), LN2i), fromUInt(hl))))), x) / N0u;
  }

  function mul(
      int128 x, int128 y
  )
      internal
      pure
      returns (int128)
  {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
  }

  function mulu(
      int128 x,
      uint256 y
  )
      internal
      pure
      returns (uint256)
  {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;

      uint256 hi = uint256 (int(x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
  }

  function div(
      int128 x,
      int128 y
  )
      internal
      pure
      returns (int128)
  {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
  }

  function inv(
      int128 x
  )
      internal
      pure
      returns (int128)
  {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
  }

  function exp_2(
      int128 x
  )
      internal
      pure
      returns (int128)
  {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int(63 - (x >> 64)));

      require (result <= uint256 (int(MAX_64x64)));

      return int128 (int(result));
  }

  function exp(
      int128 x
  )
      internal
      pure
      returns (int128)
  {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  function fromUInt(
      uint256 x
  )
      internal
      pure
      returns (int128)
  {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int(x << 64));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRouter {
    function factory() external view returns (address);

    function sync() external;

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

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

    function getPair(
        address,
        address
    ) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPair {
    function getReserves() external returns (uint, uint, uint);

    function token0() external returns (address);

    function balanceOf(
        address account
    ) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);
    
    function sync() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IGovernanceToken {
    function totalSupply() external view returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(
        address account
    ) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function rebalance(
        int256 amount,
        address sender,
        address recipient,
        address delegatee
    ) external;

    function delegate(
        address delegatee
    ) external;

    function setWhitelist(
        address to,
        bool allowed
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IToken {
    function totalSupply() external view returns (uint256);

    function buyTaxPermille() external view returns (uint256);

    function balanceOf(
        address account
    ) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function rebalance(
        int256 amount,
        address account
    ) external;

    function sync(
        address pair,
        uint256 amount
    ) external;
}