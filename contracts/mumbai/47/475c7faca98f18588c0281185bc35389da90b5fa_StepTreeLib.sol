// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "./DataTypes.sol";
import {IStep} from "../steps/IStep.sol";

/// @title Step Tree
/// @author danyams & naveenailawadi

/** @dev This library is to be used by the vault to track its steps and for the steps' winding and unwinding
 * Specification: 
 * - The tree's nodes have a max of 9 children per node
 * - Each node can only have one parent.  
 * - Each node keeps track of its step address and wind percent.  
 * - Upon insertion, node's children are inserted sequentially. 
 * - The summation of a node's childrens' wind percents cannot be greater than PRECISION_FACTOR
 * - The tree can only have up to 10 nodes, including the root node
 * - During winding, a child node cannot be wound before its parent. This does not apply to the root node
 * - During unwinding, a parent cannot be unwound before its children.  This does not apply to leaf nodes
 */

/**
 * Invariants:
 *  - The sum of a node's childrens' wind percents can never be greater than PRECISION_FACTOR
 *  - A node can never have more than 9 children
 *  - All values in the StepTree.amountsOut mapping must be 0 following a wind or unwind
 *  - A tree can never have more than 10 nodes, excluding the null node, which is the root's parent
 */

 /**
  *  Note: some functions in this library are external while others are internal. Ideally, we would have
  *  made all internal to avoid unnecessary DELEGATECALLs.  However, we needed to make some external to 
  *  reduce the Vault's contract size, which uses this library.
  *
  *  The recursive functions of windSteps() and unwindSteps() were kept as internal, since they would require
  *  O(n) DELEGATECALLs, where n is the number of steps in a vault
  */
library StepTreeLib {
    /// Errors
    /**
     * The wind percent passed in during insertion is too large: it would make the summation of the 
     * node's childrens' wind percents > PRECISION_FACTOR
     */
    error NodeWindPercentTooLarge();

    /**
     * The parent node's key passed in during insertion is null: it is either 0 or >= self.nextNodeIndex
     * If a key is >= self.nextNodeIndex, it is null because a node has not yet been inserted with that key
     */
    error NonRootNodeNullParent();

    /**
     * The wind percent passed in during the insertion of an internal node or leaf is zero
     */
    error NonRootNodeWindPercentZero();

    /**
     * The passed in parent index for the root node during insertion is null (i.e. 0)
     */
    error RootNodeNonNullParent();
    
    /**
     * The passed in parent index for the root node during insertion is > 0
     */
    error RootWindPercentNotZero();

    uint256 internal constant PRECISION_FACTOR = 1_000_000;

    /// The root is indexed @ 1. It's parent's key = 0 to signify that it is null
    struct StepTree {
        uint8 root;
        uint8 nextNodeKey;
        // Amounts out by node index during a windSteps() or unwindSteps(). These values are cleared at the end of the function
        mapping(uint256 => uint256) amountsOut;
        // nodeKey => tokensProduced
        mapping(uint256 => uint256) tokensProduced;
        mapping(uint256 => Node) nodes;
    }

    // uint8s are used since no child or parent's index will ever be greater than 10
    // Node struct fits into two storage slots
    struct Node {
        // 1st storage slot
        uint8 parent;
        uint8[9] children;
        uint8 key;
        address stepAddress;
        // 2nd storage slot
        uint256 windPercent;
    }

    /// Two cases:
    /// 1. The node is the root node
    /// 2. The node is not the root node
    function insert(StepTree storage self, address _stepAddress, uint256 _windPercent, uint8 _parentNodeKey)
        external
        returns (uint8)
    {
        // Case 1: The node is the root node
        if (self.root == 0) {
            // The following checks are not necessary. However, it guarauntees that the input from the frontend is intentional
            // about which step to set as the root
            if (_parentNodeKey != 0) revert RootNodeNonNullParent();
            if (_windPercent != 0) revert RootWindPercentNotZero();

            // Cache the new root value, which is 1
            uint8 rootKeyCache = 1;

            // Update the root
            self.root = rootKeyCache;

            uint8[9] memory emptyChildren;

            // Assign in 2 SSTOREs
            self.nodes[rootKeyCache] =
                Node({parent: 0, children: emptyChildren, key: rootKeyCache, stepAddress: _stepAddress, windPercent: 0});

            // Update the nextNodeKey
            self.nextNodeKey = rootKeyCache + 1;

            // Return the root's key
            return rootKeyCache;
        }
        // Case 2: The node is not the root node
        else {
            // Cache the parentNode & nextNodeKey
            Node memory parentNodeCache = self.nodes[_parentNodeKey];
            uint8 nextNodeKeyCache = self.nextNodeKey;

            // Internal node's parent cannot be null
            if (parentNodeCache.key == 0 || parentNodeCache.key >= self.nextNodeKey) revert NonRootNodeNullParent();

            // Wind percent cannot be 0, otherwise the step is effectively null
            if (_windPercent == 0) revert NonRootNodeWindPercentZero();

            uint256 i; // uint8 i = 0;
            uint256 childrenWindPercents;

            // While the nodes of the parent's children are not null, iterate.
            // Will revert if the parent has 9 non-null, children
            while (parentNodeCache.children[i] != 0) {
                childrenWindPercents = childrenWindPercents + self.nodes[parentNodeCache.children[i]].windPercent;
                unchecked {
                    ++i;
                }
            }

            // Children wind percents can never be greater than 100%
            childrenWindPercents = childrenWindPercents + _windPercent;
            if (childrenWindPercents > PRECISION_FACTOR) revert NodeWindPercentTooLarge();

            // Update the parent's children array
            self.nodes[_parentNodeKey].children[i] = nextNodeKeyCache;

            uint8[9] memory emptyChildren;

            // Update self.nodes in 1 SSTORE
            self.nodes[nextNodeKeyCache] = Node({
                parent: _parentNodeKey,
                children: emptyChildren,
                key: nextNodeKeyCache,
                stepAddress: _stepAddress,
                windPercent: _windPercent
            });

            // Iterate the nextNodeKey
            unchecked {
                ++self.nextNodeKey;
            }

            // Return node index of the new node
            return nextNodeKeyCache;
        }
    }

    /**
     * @dev External function to initiate the recursion for winding steps
     */
    function windSteps(StepTree storage self, address _caller, uint256 _rootAmountIn, bytes[] memory _variableArgs)
        external
    {
        // Start recursion
        windSteps(self, self.nodes[self.root], _caller, _rootAmountIn, _variableArgs);

        // Clear the amounts out mapping
        clearAmountsOut(self);
    }

    /**
     * @dev Internal recursive function for winding steps
     */
    function windSteps(
        StepTree storage self,
        Node memory _node,
        address _caller,
        uint256 _rootAmountIn,
        bytes[] memory _variableArgs
    ) internal {
        // Empty case
        if (_node.key == 0) return;

        // Need to account for the root case
        uint256 amountIn = _isRootNode(_node)
            ? _rootAmountIn
            : ((self.amountsOut[_node.parent] * _node.windPercent) / PRECISION_FACTOR);

        // Visit Node: wind the step
         uint256 amountOut =
            IStep(_node.stepAddress).wind(_caller, _node.key, amountIn, _variableArgs[_node.key - 1]); // _variableArgs are indexed @ 0, adjust accordingly

        // The amountsOut mapping during windSteps() is used so that children know its parents output throughout recursive calls
        // However, leaves have no children.  No point in wasting an SSTORE on them
        if (!(_isLeafNode(_node))) {
            self.amountsOut[_node.key] = amountOut;
        }

        // Update the internal accounting 
        self.tokensProduced[_node.key] = self.tokensProduced[_node.key] + amountOut;

        // This should never revert: this wind only executes after a parent has been wound
        // Since the summation of the wind percents of a node's children cannot be greater than 100%, 
        // the summation of the decrements through recursive calls cannot be greater than self.tokensProduced[node.key] 
        // Obviously, we also have to address the root case
        if(!(_isRootNode(_node))) {
            self.tokensProduced[_node.parent] = self.tokensProduced[_node.parent] - amountIn; 
        }
        
        // A node will never have more than 9 children
        for (uint256 i; i < 9;) {
            // If the node's ith child is null, break. The following children will also be null
            if (self.nodes[_node.children[i]].key == 0) break;

            // Recurse
            windSteps(self, self.nodes[_node.children[i]], _caller, _rootAmountIn, _variableArgs);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev External function to initiate the recursion for unwinding steps
     * Assumption: _totalSupply is not zero
     */
    function unwindSteps(
        StepTree storage self,
        address _caller,
        uint256 _sharesRedeemed,
        uint256 _totalSupply,
        bytes[] memory _variableArgs
    ) external {
        // Start recursion
        unwindSteps(self, self.nodes[self.root], _caller, _sharesRedeemed, _totalSupply, _variableArgs);

        // Clear the amounts out mapping
        clearAmountsOut(self);
    }

    /**
     * @dev Internal recursive function for unwinding steps
     */
    function unwindSteps(
        StepTree storage self,
        Node memory _node,
        address _caller,
        uint256 _sharesRedeemed,
        uint256 _totalSupply,
        bytes[] memory _variableArgs
    ) internal {
        // Addresses the empty case
        if (_node.key == 0) return;

        // A node will never have more than 9 children
        for (uint256 i; i < 9;) {
            // If the node's child's is null, return.  The following children will also be null
            if (self.nodes[_node.children[i]].key == 0) break;

            // Recurse
            unwindSteps(self, self.nodes[_node.children[i]], _caller, _sharesRedeemed, _totalSupply, _variableArgs);

            unchecked {
                ++i;
            }
        }

        // Update the internal accounting

        // The number of tokens that is redeemed is based on the %% of the shares being redeemed compared to the total supply
        uint256 tokensRedeemed = (_sharesRedeemed * self.tokensProduced[_node.key]) / _totalSupply;

        // Decrement this amount from the tokensProduced mapping for the given node
        self.tokensProduced[_node.key] = self.tokensProduced[_node.key] - tokensRedeemed;

        // The amountIn for the next step is the sum of the tokensRedeemed and the summation of the node's childrens' amounts out
        uint256 amountIn = tokensRedeemed;

        // Add to the amountIn the summation of amountsOut of the current node's children
        for (uint256 i; i < 9;) {
            if (self.nodes[_node.children[i]].key == 0) break;

            // Add the amountOut of node's children to the amount in for the next unwind
            amountIn = amountIn + self.amountsOut[_node.children[i]];

            unchecked {
                ++i;
            }
        }

        // Visit the node 
        uint256 amountOut =
            IStep(_node.stepAddress).unwind(_caller, _node.key, amountIn, _variableArgs[_node.key - 1]); // _variables args are indexed @ 0; adjust accordingly

        // The amountsOut mapping during unwindSteps() is used so that parents know its childrens outputs throughout recursive calls
        // However, the root has no parent.  No point in wasting an SSTORE on it
        if (!(_isRootNode(_node))) {
            self.amountsOut[_node.key] = amountOut;
        }
    }

    /**
     * @dev Internal function that clears the self.amountsOut mapping. Called following windSteps() and unwindSteps()
     */
    function clearAmountsOut(StepTree storage self) internal {
        // Add 1 here since amountsOut uses a node's key, which are indexed @ 1
        // This is done to avoid using <= in place of < in the for loop
        uint256 len = size(self) + 1;

        for (uint256 i = 1; i < len;) {
            delete self.amountsOut[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Internal view function that returns the size of the tree. Since node 
     * key's are sequential, the size of the tree is self.nextNodeKey - 1
     */
    function size(StepTree storage self) internal view returns (uint8) {
        return self.root == 0 ? 0 : (self.nextNodeKey - 1);
    }

    /**
     * @dev Private pure function that returns a bool indiciating whether or not a node is a leaf
     */
    function _isLeafNode(Node memory _node) private pure returns (bool) {
        // If a node's first child is null, it's remaining children will also be null
        return _node.children[0] == 0;
    }

    /**
     * @dev Private pure function that returns a bool indiciating whether or not the node is the root node
     */
    function _isRootNode(Node memory _node) private pure returns (bool) {
        return _node.parent == 0;
    }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

// To Do: Order alphabetically
library DataTypes {
    /////////////////////////////
    ///   Global Data Types   ///
    ////////////////////////////

    // basic step routing information
    struct StepInfo {
        address interactionAddress;
        uint8 parentIndex;
        uint256 windPercent;
        bytes fixedArgData;
    }

    // user expectations for the withdrawal assets (can't check with oracles in worst-case)
    // note: the amount is not being stored or used often, so best to keep it as a uint256 in case users have a ton of a bespoke token
    struct AssetExpectation {
        address assetAddress;
        uint256 amount;
    }

    /**
     *  Unpaused: All protocol actions enabled
     *  Paused: Creation of new trade paused.  Copying and exiting trades still possible.
     *  Frozen: Copying and creating new trades paused.  Exiting trades still possible
     */
    enum ProtocolState {
        Unpaused,
        Paused,
        Frozen
    }

    /**
     *  Disabled: No functionality
     *  Deprecated: Unwind existing strategies
     *  Legacy: Wind and unwind existing strategies
     *  Enabled: Wind, unwind, create new strategies
     */
    enum StepState {
        Disabled,
        Deprecated,
        Legacy,
        Enabled
    }

    ///////////////////////////////////////
    ///   Price Aggregator Data Types   ///
    ///////////////////////////////////////

    enum RateAsset {
        USD,
        ETH
    }

    struct SupportedAssetInfo {
        AggregatorV3Interface aggregator;
        RateAsset rateAsset;
        uint256 units;
    }

    /////////////////////////////////////
    ///   Fee Controller Data Types   ///
    /////////////////////////////////////

    struct FeeInfo {
        uint24 entranceFee;
        uint24 exitFee;
        uint24 performanceFee;
        uint24 managementFee;
        address collector;
    }

    struct FeesPayable {
        uint256 dremFee;
        uint256 adminFee;
    }

    /////////////////////////////////////
    ///   Vault Deployer Data Types   ///
    /////////////////////////////////////

    struct DeploymentInfo {
        address admin;
        string name;
        string symbol;
        address denominationAsset;
        StepInfo[] steps;
        FeeInfo feeInfo;
    }

    //////////////////////////////////
    ///   Global Step Data Types   ///
    //////////////////////////////////

    struct UnwindInfo {
        uint256 sharesRedeemed;
        uint256 totalSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IStep {
    // initialize the step (unknown amount of bytes --> must be decoded)
    function init(uint256 stepIndex, bytes calldata fixedArgs) external;

    // wind and unwind the step to move forwards and backwards
    function wind(address caller, uint256 argIndex, uint256 amountIn, bytes memory variableArgs)
        external
        returns (uint256);

    function unwind(
        address caller,
        uint256 argIndex,
        uint256 amountIn,
        bytes memory variableArgs
    ) external returns (uint256);

    // get the value based on the step's interactions
    function value(uint256 argIndex, address denominationAsset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}