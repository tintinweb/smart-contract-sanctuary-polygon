// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../domain/BosonConstants.sol";
import { IBosonAccountEvents } from "../../interfaces/events/IBosonAccountEvents.sol";
import { DiamondLib } from "../../diamond/DiamondLib.sol";
import { ProtocolBase } from "../bases/ProtocolBase.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";

/**
 * @title DisputeResolverHandlerFacet
 *
 * @notice Handles dispute resolver account management requests and queries
 */
contract DisputeResolverHandlerFacet is IBosonAccountEvents, ProtocolBase {
    /**
     * @notice Initializes facet.
     */
    function initialize() public {
        // No-op initializer.
        // - needed by the deployment script, which expects a no-args initializer on facets other than the config handler
        // - exception here because IBosonAccountHandler is contributed to by multiple facets which do not have their own individual interfaces
    }

    /**
     * @notice Creates a dispute resolver. Dispute resolver must be activated before it can participate in the protocol.
     *
     * Emits a DisputeResolverCreated event if successful.
     *
     * Reverts if:
     * - Caller is not the supplied admin, operator and clerk
     * - The dispute resolvers region of protocol is paused
     * - Any address is zero address
     * - Any address is not unique to this dispute resolver
     * - Number of DisputeResolverFee structs in array exceeds max
     * - DisputeResolverFee array contains duplicates
     * - EscalationResponsePeriod is invalid
     * - Number of seller ids in _sellerAllowList array exceeds max
     * - Some seller does not exist
     * - Some seller id is duplicated
     *
     * @param _disputeResolver - the fully populated struct with dispute resolver id set to 0x0
     * @param _disputeResolverFees - array of fees dispute resolver charges per token type. Zero address is native currency. Can be empty.
     * @param _sellerAllowList - list of ids of sellers that can choose this dispute resolver. If empty, there are no restrictions on which seller can chose it.
     */
    function createDisputeResolver(
        DisputeResolver memory _disputeResolver,
        DisputeResolverFee[] calldata _disputeResolverFees,
        uint256[] calldata _sellerAllowList
    ) external disputeResolversNotPaused nonReentrant {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        // Check for zero address
        require(
            _disputeResolver.admin != address(0) &&
                _disputeResolver.operator != address(0) &&
                _disputeResolver.clerk != address(0) &&
                _disputeResolver.treasury != address(0),
            INVALID_ADDRESS
        );

        // Scope to avoid stack too deep errors
        {
            // Get message sender
            address sender = msgSender();

            // Check that caller is the supplied operator and clerk
            require(
                _disputeResolver.admin == sender &&
                    _disputeResolver.operator == sender &&
                    _disputeResolver.clerk == sender,
                NOT_ADMIN_OPERATOR_AND_CLERK
            );
        }

        // Get the next account id and increment the counter
        uint256 disputeResolverId = protocolCounters().nextAccountId++;

        // Check that the addresses are unique to one dispute resolver id, across all rolls
        mapping(address => uint256) storage disputeResolverIdByOperator = lookups.disputeResolverIdByOperator;
        mapping(address => uint256) storage disputeResolverIdByAdmin = lookups.disputeResolverIdByAdmin;
        mapping(address => uint256) storage disputeResolverIdByClerk = lookups.disputeResolverIdByClerk;
        require(
            disputeResolverIdByOperator[_disputeResolver.operator] == 0 &&
                disputeResolverIdByOperator[_disputeResolver.admin] == 0 &&
                disputeResolverIdByOperator[_disputeResolver.clerk] == 0 &&
                disputeResolverIdByAdmin[_disputeResolver.admin] == 0 &&
                disputeResolverIdByAdmin[_disputeResolver.operator] == 0 &&
                disputeResolverIdByAdmin[_disputeResolver.clerk] == 0 &&
                disputeResolverIdByClerk[_disputeResolver.clerk] == 0 &&
                disputeResolverIdByClerk[_disputeResolver.operator] == 0 &&
                disputeResolverIdByClerk[_disputeResolver.admin] == 0,
            DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE
        );

        // Scope to avoid stack too deep errors
        {
            // Cache protocol limits for reference
            ProtocolLib.ProtocolLimits storage limits = protocolLimits();

            // Make sure the gas block limit is not hit
            require(_sellerAllowList.length <= limits.maxAllowedSellers, INVALID_AMOUNT_ALLOWED_SELLERS);

            // The number of fees cannot exceed the maximum number of dispute resolver fees to avoid running into block gas limit in a loop
            require(
                _disputeResolverFees.length <= limits.maxFeesPerDisputeResolver,
                INVALID_AMOUNT_DISPUTE_RESOLVER_FEES
            );

            // Escalation period must be greater than zero and less than or equal to the max allowed
            require(
                _disputeResolver.escalationResponsePeriod > 0 &&
                    _disputeResolver.escalationResponsePeriod <= limits.maxEscalationResponsePeriod,
                INVALID_ESCALATION_PERIOD
            );
        }

        _disputeResolver.id = disputeResolverId;

        // Get storage location for dispute resolver fees
        (, , DisputeResolverFee[] storage disputeResolverFees) = fetchDisputeResolver(_disputeResolver.id);

        // Set dispute resolver fees. Must loop because calldata structs cannot be converted to storage structs
        mapping(address => uint256) storage disputeResolverFeeTokens = lookups.disputeResolverFeeTokenIndex[
            _disputeResolver.id
        ];
        for (uint256 i = 0; i < _disputeResolverFees.length; i++) {
            require(
                disputeResolverFeeTokens[_disputeResolverFees[i].tokenAddress] == 0,
                DUPLICATE_DISPUTE_RESOLVER_FEES
            );
            disputeResolverFees.push(_disputeResolverFees[i]);

            // Set index mapping. Should be index in disputeResolverFees array + 1
            disputeResolverFeeTokens[_disputeResolverFees[i].tokenAddress] = disputeResolverFees.length;
        }

        // Ignore supplied active flag and set to false. Dispute resolver must be activated by protocol.
        _disputeResolver.active = false;

        storeDisputeResolver(_disputeResolver);
        storeSellerAllowList(disputeResolverId, _sellerAllowList);

        // Notify watchers of state change
        emit DisputeResolverCreated(
            _disputeResolver.id,
            _disputeResolver,
            _disputeResolverFees,
            _sellerAllowList,
            msgSender()
        );
    }

    /**
     * @notice Updates treasury address, escalationResponsePeriod or metadataUri if changed. Puts admin, operator and clerk in pending queue, if changed.
     *         Pending updates can be completed by calling the optInToDisputeResolverUpdate function.
     *
     *         Update doesn't include DisputeResolverFees, allowed seller list or active flag.
     *         All DisputeResolver fields should be filled, even those staying the same.
     *         Use removeFeesFromDisputeResolver and addFeesToDisputeResolver to add and remove fees.
     *         Use addSellersToAllowList and removeSellersFromAllowList to add and remove allowed sellers.
     *
     * @dev    Active flag passed in by caller will be ignored. The value from storage will be used.
     *
     * Emits a DisputeResolverUpdated event if successful.
     * Emits a DisputeResolverUpdatePending event if the dispute resolver has requested an update for admin, clerk or operator.
     * Owner(s) of new addresses for admin, clerk, operator must opt-in to the update.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address of the stored dispute resolver
     * - Any address is zero address
     * - Any address is not unique to this dispute resolver
     * - Dispute resolver does not exist
     * - EscalationResponsePeriod is invalid
     *
     * @param _disputeResolver - the fully populated dispute resolver struct
     */
    function updateDisputeResolver(DisputeResolver memory _disputeResolver)
        external
        disputeResolversNotPaused
        nonReentrant
    {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        // Check for zero address
        require(
            _disputeResolver.admin != address(0) &&
                _disputeResolver.operator != address(0) &&
                _disputeResolver.clerk != address(0) &&
                _disputeResolver.treasury != address(0),
            INVALID_ADDRESS
        );

        bool exists;
        DisputeResolver storage disputeResolver;

        // Check dispute resolver and dispute resolver Fees from disputeResolvers and disputeResolverFees mappings
        (exists, disputeResolver, ) = fetchDisputeResolver(_disputeResolver.id);

        // Dispute resolver must already exist
        require(exists, NO_SUCH_DISPUTE_RESOLVER);

        // Get message sender
        address sender = msgSender();

        // Check that caller is the admin address for this dispute resolver
        require(disputeResolver.admin == sender, NOT_ADMIN);

        // Clean old dispute resolver pending update data if exists
        delete lookups.pendingAddressUpdatesByDisputeResolver[_disputeResolver.id];

        bool needsApproval;
        (, DisputeResolver storage disputeResolverPendingUpdate) = fetchDisputeResolverPendingUpdate(
            _disputeResolver.id
        );

        if (_disputeResolver.admin != disputeResolver.admin) {
            preUpdateDisputeResolverCheck(_disputeResolver.id, _disputeResolver.admin, lookups);

            // If admin address exists, admin address owner must approve the update to prevent front-running
            disputeResolverPendingUpdate.admin = _disputeResolver.admin;
            needsApproval = true;
        }

        if (_disputeResolver.operator != disputeResolver.operator) {
            preUpdateDisputeResolverCheck(_disputeResolver.id, _disputeResolver.operator, lookups);

            // If operator address exists, operator address owner must approve the update to prevent front-running
            disputeResolverPendingUpdate.operator = _disputeResolver.operator;
            needsApproval = true;
        }

        if (_disputeResolver.clerk != disputeResolver.clerk) {
            preUpdateDisputeResolverCheck(_disputeResolver.id, _disputeResolver.clerk, lookups);

            // If clerk address exists, clerk address owner must approve the update to prevent front-running
            disputeResolverPendingUpdate.clerk = _disputeResolver.clerk;
            needsApproval = true;
        }

        bool updateApplied;

        if (_disputeResolver.treasury != disputeResolver.treasury) {
            // Update treasury
            disputeResolver.treasury = _disputeResolver.treasury;

            updateApplied = true;
        }

        if (_disputeResolver.escalationResponsePeriod != disputeResolver.escalationResponsePeriod) {
            // Escalation period must be greater than zero and less than or equal to the max allowed
            require(
                _disputeResolver.escalationResponsePeriod > 0 &&
                    _disputeResolver.escalationResponsePeriod <= protocolLimits().maxEscalationResponsePeriod,
                INVALID_ESCALATION_PERIOD
            );

            // Update escalation response period
            disputeResolver.escalationResponsePeriod = _disputeResolver.escalationResponsePeriod;

            updateApplied = true;
        }

        if (keccak256(bytes(_disputeResolver.metadataUri)) != keccak256(bytes(disputeResolver.metadataUri))) {
            // Update metadata URI
            disputeResolver.metadataUri = _disputeResolver.metadataUri;

            updateApplied = true;
        }

        if (needsApproval) {
            // Notify watchers of state change
            emit DisputeResolverUpdatePending(_disputeResolver.id, disputeResolverPendingUpdate, sender);
        }

        if (updateApplied) {
            // Notify watchers of state change
            emit DisputeResolverUpdateApplied(
                _disputeResolver.id,
                disputeResolver,
                disputeResolverPendingUpdate,
                sender
            );
        }
    }

    /**
     * @notice Opt-in to a pending dispute resolver update
     *
     * Emits a DisputeResolverUpdateApplied event if successful.
     *
     * Reverts if:
     * - The dispute resolver region of protocol is paused
     * - Addresses are not unique to this dispute resolver
     * - Caller address is not pending update for the field being updated
     * - No pending update exists for this dispute resolver
     *
     * @param _disputeResolverId - disputeResolver id
     * @param _fieldsToUpdate - fields to update, see DisputeResolverUpdateFields enum
     */
    function optInToDisputeResolverUpdate(
        uint256 _disputeResolverId,
        DisputeResolverUpdateFields[] calldata _fieldsToUpdate
    ) external disputeResolversNotPaused nonReentrant {
        // Cache protocol lookups and sender for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();
        address sender = msgSender();

        // Get disputeResolver pending update
        (bool exists, DisputeResolver storage disputeResolverPendingUpdate) = fetchDisputeResolverPendingUpdate(
            _disputeResolverId
        );

        require(exists, NO_PENDING_UPDATE_FOR_ACCOUNT);

        bool updateApplied;

        // Get storage location for disputeResolver
        (, DisputeResolver storage disputeResolver, ) = fetchDisputeResolver(_disputeResolverId);

        for (uint256 i = 0; i < _fieldsToUpdate.length; i++) {
            DisputeResolverUpdateFields role = _fieldsToUpdate[i];

            if (role == DisputeResolverUpdateFields.Admin && disputeResolverPendingUpdate.admin != address(0)) {
                // Approve admin update
                require(disputeResolverPendingUpdate.admin == sender, UNAUTHORIZED_CALLER_UPDATE);

                preUpdateDisputeResolverCheck(_disputeResolverId, sender, lookups);

                // Delete old disputeResolver id by admin mapping
                delete lookups.disputeResolverIdByAdmin[disputeResolver.admin];

                // Update admin
                disputeResolver.admin = sender;

                // Store new disputeResolver id by admin mapping
                lookups.disputeResolverIdByAdmin[sender] = _disputeResolverId;

                // Delete pending update admin
                delete disputeResolverPendingUpdate.admin;

                updateApplied = true;
            } else if (
                role == DisputeResolverUpdateFields.Operator && disputeResolverPendingUpdate.operator != address(0)
            ) {
                // Approve operator update
                require(disputeResolverPendingUpdate.operator == sender, UNAUTHORIZED_CALLER_UPDATE);

                preUpdateDisputeResolverCheck(_disputeResolverId, sender, lookups);

                // Delete old disputeResolver id by operator mapping
                delete lookups.disputeResolverIdByOperator[disputeResolver.operator];

                // Update operator
                disputeResolver.operator = sender;

                // Store new disputeResolver id by operator mapping
                lookups.disputeResolverIdByOperator[sender] = _disputeResolverId;

                // Delete pending update operator
                delete disputeResolverPendingUpdate.operator;

                updateApplied = true;
            } else if (role == DisputeResolverUpdateFields.Clerk && disputeResolverPendingUpdate.clerk != address(0)) {
                // Aprove clerk update
                require(disputeResolverPendingUpdate.clerk == sender, UNAUTHORIZED_CALLER_UPDATE);

                preUpdateDisputeResolverCheck(_disputeResolverId, sender, lookups);

                // Delete old disputeResolver id by clerk mapping
                delete lookups.disputeResolverIdByClerk[disputeResolver.clerk];

                // Update clerk
                disputeResolver.clerk = sender;

                // Store new disputeResolver id by clerk mapping
                lookups.disputeResolverIdByClerk[sender] = _disputeResolverId;

                // Delete pending update clerk
                delete disputeResolverPendingUpdate.clerk;

                updateApplied = true;
            }
        }

        if (updateApplied) {
            // Notify watchers of state change
            emit DisputeResolverUpdateApplied(
                _disputeResolverId,
                disputeResolver,
                disputeResolverPendingUpdate,
                sender
            );
        }
    }

    /**
     * @notice Adds DisputeResolverFees to an existing dispute resolver.
     *
     * Emits a DisputeResolverFeesAdded event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of DisputeResolverFee structs in array exceeds max
     * - Number of DisputeResolverFee structs in array is zero
     * - DisputeResolverFee array contains duplicates
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     */
    function addFeesToDisputeResolver(uint256 _disputeResolverId, DisputeResolverFee[] calldata _disputeResolverFees)
        external
        disputeResolversNotPaused
        nonReentrant
    {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        bool exists;
        DisputeResolver storage disputeResolver;
        DisputeResolverFee[] storage disputeResolverFees;

        // Check dispute resolver and dispute resolver Fees from disputeResolvers and disputeResolverFees mappings
        (exists, disputeResolver, disputeResolverFees) = fetchDisputeResolver(_disputeResolverId);

        // Dispute resolver must already exist
        require(exists, NO_SUCH_DISPUTE_RESOLVER);

        // Get message sender
        address sender = msgSender();

        // Check that msg.sender is the admin address for this dispute resolver
        require(disputeResolver.admin == sender, NOT_ADMIN);

        // At least one fee must be specified and the number of fees cannot exceed the maximum number of dispute resolver fees to avoid running into block gas limit in a loop
        require(
            _disputeResolverFees.length > 0 &&
                _disputeResolverFees.length <= protocolLimits().maxFeesPerDisputeResolver,
            INVALID_AMOUNT_DISPUTE_RESOLVER_FEES
        );

        // Set dispute resolver fees. Must loop because calldata structs cannot be converted to storage structs
        for (uint256 i = 0; i < _disputeResolverFees.length; i++) {
            require(
                lookups.disputeResolverFeeTokenIndex[_disputeResolverId][_disputeResolverFees[i].tokenAddress] == 0,
                DUPLICATE_DISPUTE_RESOLVER_FEES
            );
            disputeResolverFees.push(_disputeResolverFees[i]);
            lookups.disputeResolverFeeTokenIndex[_disputeResolverId][
                _disputeResolverFees[i].tokenAddress
            ] = disputeResolverFees.length; // Set index mapping. Should be index in disputeResolverFees array + 1
        }

        emit DisputeResolverFeesAdded(_disputeResolverId, _disputeResolverFees, sender);
    }

    /**
     * @notice Removes DisputeResolverFees from  an existing dispute resolver.
     *
     * Emits a DisputeResolverFeesRemoved event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of DisputeResolverFee structs in array exceeds max
     * - Number of DisputeResolverFee structs in array is zero
     * - DisputeResolverFee does not exist for the dispute resolver
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _feeTokenAddresses - list of addresses of dispute resolver fee tokens to remove
     */
    function removeFeesFromDisputeResolver(uint256 _disputeResolverId, address[] calldata _feeTokenAddresses)
        external
        disputeResolversNotPaused
        nonReentrant
    {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        bool exists;
        DisputeResolver storage disputeResolver;
        DisputeResolverFee[] storage disputeResolverFees;

        // Check dispute resolver and dispute resolver fees from disputeResolvers and disputeResolverFees mappings
        (exists, disputeResolver, disputeResolverFees) = fetchDisputeResolver(_disputeResolverId);

        // Dispute resolver must already exist
        require(exists, NO_SUCH_DISPUTE_RESOLVER);

        // Get message sender
        address sender = msgSender();

        // Check that msg.sender is the admin address for this dispute resolver
        require(disputeResolver.admin == sender, NOT_ADMIN);

        // At least one fee must be specified and the number of fees cannot exceed the maximum number of dispute resolver fees to avoid running into block gas limit in a loop
        require(
            _feeTokenAddresses.length > 0 && _feeTokenAddresses.length <= protocolLimits().maxFeesPerDisputeResolver,
            INVALID_AMOUNT_DISPUTE_RESOLVER_FEES
        );

        // Set dispute resolver fees. Must loop because calldata structs cannot be converted to storage structs
        for (uint256 i = 0; i < _feeTokenAddresses.length; i++) {
            require(
                lookups.disputeResolverFeeTokenIndex[_disputeResolverId][_feeTokenAddresses[i]] != 0,
                DISPUTE_RESOLVER_FEE_NOT_FOUND
            );
            uint256 disputeResolverFeeArrayIndex = lookups.disputeResolverFeeTokenIndex[_disputeResolverId][
                _feeTokenAddresses[i]
            ] - 1; //Get the index in the DisputeResolverFees array, which is 1 less than the disputeResolverFeeTokenIndex index

            uint256 lastTokenIndex = disputeResolverFees.length - 1;
            if (disputeResolverFeeArrayIndex != lastTokenIndex) {
                // if index == len - 1 then only pop and delete are needed
                // Need to fill gap caused by delete if more than one element in storage array
                DisputeResolverFee memory disputeResolverFeeToMove = disputeResolverFees[lastTokenIndex];
                disputeResolverFees[disputeResolverFeeArrayIndex] = disputeResolverFeeToMove; // Copy the last DisputeResolverFee struct in the array to this index to fill the gap
                lookups.disputeResolverFeeTokenIndex[_disputeResolverId][disputeResolverFeeToMove.tokenAddress] =
                    disputeResolverFeeArrayIndex +
                    1; // Reset index mapping. Should be index in disputeResolverFees array + 1
            }
            disputeResolverFees.pop(); // Delete last DisputeResolverFee struct in the array, which was just moved to fill the gap
            delete lookups.disputeResolverFeeTokenIndex[_disputeResolverId][_feeTokenAddresses[i]]; // Delete from index mapping
        }

        emit DisputeResolverFeesRemoved(_disputeResolverId, _feeTokenAddresses, sender);
    }

    /**
     * @notice Adds seller ids to set of ids allowed to choose the given dispute resolver for an offer.
     *
     * Emits an AllowedSellersAdded event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of seller ids in array exceeds max
     * - Number of seller ids in array is zero
     * - Some seller does not exist
     * - Seller id is already approved
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _sellerAllowList - list of seller ids to add to allowed list
     */
    function addSellersToAllowList(uint256 _disputeResolverId, uint256[] calldata _sellerAllowList)
        external
        disputeResolversNotPaused
        nonReentrant
    {
        // At least one seller id must be specified and the number of ids cannot exceed the maximum number of seller ids to avoid running into block gas limit in a loop
        require(
            _sellerAllowList.length > 0 && _sellerAllowList.length <= protocolLimits().maxAllowedSellers,
            INVALID_AMOUNT_ALLOWED_SELLERS
        );
        bool exists;
        DisputeResolver storage disputeResolver;

        // Check dispute Resolver from disputeResolvers
        (exists, disputeResolver, ) = fetchDisputeResolver(_disputeResolverId);

        // Dispute resolver must already exist
        require(exists, NO_SUCH_DISPUTE_RESOLVER);

        // Get message sender
        address sender = msgSender();

        // Check that msg.sender is the admin address for this dispute resolver
        require(disputeResolver.admin == sender, NOT_ADMIN);

        storeSellerAllowList(_disputeResolverId, _sellerAllowList);

        emit AllowedSellersAdded(_disputeResolverId, _sellerAllowList, sender);
    }

    /**
     * @notice Removes seller ids from set of ids allowed to choose the given dispute resolver for an offer.
     *
     * Emits an AllowedSellersRemoved event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller is not the admin address associated with the dispute resolver account
     * - Dispute resolver does not exist
     * - Number of seller ids in array exceeds max
     * - Number of seller ids structs in array is zero
     * - Seller id is not approved
     *
     * @param _disputeResolverId - id of the dispute resolver
     * @param _sellerAllowList - list of seller ids to remove from allowed list
     */
    function removeSellersFromAllowList(uint256 _disputeResolverId, uint256[] calldata _sellerAllowList)
        external
        disputeResolversNotPaused
        nonReentrant
    {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        // At least one seller id must be specified and the number of ids cannot exceed the maximum number of seller ids to avoid running into block gas limit in a loop
        require(
            _sellerAllowList.length > 0 && _sellerAllowList.length <= protocolLimits().maxAllowedSellers,
            INVALID_AMOUNT_ALLOWED_SELLERS
        );

        bool exists;
        DisputeResolver storage disputeResolver;

        // Check dispute resolver from disputeResolvers
        (exists, disputeResolver, ) = fetchDisputeResolver(_disputeResolverId);

        // Dispute resolver must already exist
        require(exists, NO_SUCH_DISPUTE_RESOLVER);

        // Get message sender
        address sender = msgSender();

        // Check that msg.sender is the admin address for this dispute resolver
        require(disputeResolver.admin == sender, NOT_ADMIN);

        for (uint256 i = 0; i < _sellerAllowList.length; i++) {
            uint256 sellerToRemoveIndex = lookups.allowedSellerIndex[_disputeResolverId][_sellerAllowList[i]];
            require(sellerToRemoveIndex > 0, SELLER_NOT_APPROVED);

            // remove index mapping
            delete lookups.allowedSellerIndex[_disputeResolverId][_sellerAllowList[i]];

            // reduce for 1 to get actual index value
            sellerToRemoveIndex--;

            uint256 lastIndex = lookups.allowedSellers[_disputeResolverId].length - 1; // since allowedSellerIndex > 0, length at this point cannot be 0 therefore we don't worry about overflow

            // if index to remove is not the last index we put the last element in its place
            if (sellerToRemoveIndex != lastIndex) {
                uint256 lastSellerId = lookups.allowedSellers[_disputeResolverId][lastIndex];
                lookups.allowedSellers[_disputeResolverId][sellerToRemoveIndex] = lastSellerId;
                lookups.allowedSellerIndex[_disputeResolverId][lastSellerId] = sellerToRemoveIndex + 1;
            }

            // remove last element
            lookups.allowedSellers[_disputeResolverId].pop();
        }

        emit AllowedSellersRemoved(_disputeResolverId, _sellerAllowList, sender);
    }

    /**
     * @notice Sets the active flag for this dispute resolver to true.
     *
     * @dev Only callable by the protocol ADMIN role.
     *
     * Emits a DisputeResolverActivated event if successful.
     *
     * Reverts if:
     * - The dispute resolvers region of protocol is paused
     * - Caller does not have the ADMIN role
     * - Dispute resolver does not exist
     *
     * @param _disputeResolverId - id of the dispute resolver
     */
    function activateDisputeResolver(uint256 _disputeResolverId)
        external
        disputeResolversNotPaused
        onlyRole(ADMIN)
        nonReentrant
    {
        bool exists;
        DisputeResolver storage disputeResolver;

        // Check dispute resolver and dispute resolver fees from disputeResolvers and disputeResolverFees mappings
        (exists, disputeResolver, ) = fetchDisputeResolver(_disputeResolverId);

        // Dispute resolver must already exist
        require(exists, NO_SUCH_DISPUTE_RESOLVER);

        disputeResolver.active = true;

        emit DisputeResolverActivated(_disputeResolverId, disputeResolver, msgSender());
    }

    /**
     * @notice Gets the details about a dispute resolver.
     *
     * @param _disputeResolverId - the id of the dispute resolver to check
     * @return exists - the dispute resolver was found
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     * @return disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     * @return sellerAllowList - list of sellers that are allowed to choose this dispute resolver
     */
    function getDisputeResolver(uint256 _disputeResolverId)
        public
        view
        returns (
            bool exists,
            DisputeResolver memory disputeResolver,
            DisputeResolverFee[] memory disputeResolverFees,
            uint256[] memory sellerAllowList
        )
    {
        (exists, disputeResolver, disputeResolverFees) = fetchDisputeResolver(_disputeResolverId);
        if (exists) {
            sellerAllowList = protocolLookups().allowedSellers[_disputeResolverId];
        }
    }

    /**
     * @notice Gets the details about a dispute resolver by an address associated with that dispute resolver: operator, admin, or clerk address.
     *
     * @param _associatedAddress - the address associated with the dispute resolver. Must be an operator, admin, or clerk address.
     * @return exists - the dispute resolver was found
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     * @return disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     * @return sellerAllowList - list of sellers that are allowed to chose this dispute resolver
     */
    function getDisputeResolverByAddress(address _associatedAddress)
        external
        view
        returns (
            bool exists,
            DisputeResolver memory disputeResolver,
            DisputeResolverFee[] memory disputeResolverFees,
            uint256[] memory sellerAllowList
        )
    {
        uint256 disputeResolverId;

        (exists, disputeResolverId) = getDisputeResolverIdByOperator(_associatedAddress);

        if (exists) {
            return getDisputeResolver(disputeResolverId);
        }

        (exists, disputeResolverId) = getDisputeResolverIdByAdmin(_associatedAddress);

        if (exists) {
            return getDisputeResolver(disputeResolverId);
        }

        (exists, disputeResolverId) = getDisputeResolverIdByClerk(_associatedAddress);
        if (exists) {
            return getDisputeResolver(disputeResolverId);
        }
    }

    /**
     * @notice Checks whether given sellers are allowed to choose the given dispute resolver.
     *
     * @param _disputeResolverId - id of dispute resolver to check
     * @param _sellerIds - list of seller ids to check
     * @return sellerAllowed - array with indicator (true/false) if seller is allowed to choose the dispute resolver. Index in this array corresponds to indices of the incoming _sellerIds
     */
    function areSellersAllowed(uint256 _disputeResolverId, uint256[] calldata _sellerIds)
        external
        view
        returns (bool[] memory sellerAllowed)
    {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        sellerAllowed = new bool[](_sellerIds.length);

        (bool exists, , ) = fetchDisputeResolver(_disputeResolverId);

        // We populate sellerAllowed only if id really belongs to DR, otherwise return array filled with false
        if (exists) {
            if (lookups.allowedSellers[_disputeResolverId].length == 0) {
                // DR allows everyone, just make sure ids really belong to the sellers
                for (uint256 i = 0; i < _sellerIds.length; i++) {
                    (exists, , ) = fetchSeller(_sellerIds[i]);
                    sellerAllowed[i] = exists;
                }
            } else {
                // DR is selective. Check for every seller if they are allowed for given _disputeResolverId
                for (uint256 i = 0; i < _sellerIds.length; i++) {
                    sellerAllowed[i] = lookups.allowedSellerIndex[_disputeResolverId][_sellerIds[i]] > 0; // true if on the list, false otherwise
                }
            }
        }
    }

    /**
     * @notice Stores DisputeResolver struct in storage.
     *
     * @param _disputeResolver - the fully populated struct with dispute resolver id set
     */
    function storeDisputeResolver(DisputeResolver memory _disputeResolver) internal {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        // Get storage location for dispute resolver
        (, DisputeResolver storage disputeResolver, ) = fetchDisputeResolver(_disputeResolver.id);

        // Set dispute resolver props individually since memory structs can't be copied to storage
        disputeResolver.id = _disputeResolver.id;
        disputeResolver.escalationResponsePeriod = _disputeResolver.escalationResponsePeriod;
        disputeResolver.operator = _disputeResolver.operator;
        disputeResolver.admin = _disputeResolver.admin;
        disputeResolver.clerk = _disputeResolver.clerk;
        disputeResolver.treasury = _disputeResolver.treasury;
        disputeResolver.metadataUri = _disputeResolver.metadataUri;
        disputeResolver.active = _disputeResolver.active;

        // Map the dispute resolver's addresses to the dispute resolver id.
        lookups.disputeResolverIdByOperator[_disputeResolver.operator] = _disputeResolver.id;
        lookups.disputeResolverIdByAdmin[_disputeResolver.admin] = _disputeResolver.id;
        lookups.disputeResolverIdByClerk[_disputeResolver.clerk] = _disputeResolver.id;
    }

    /**
     * @notice Stores seller id to allowed list mapping in storage.
     *
     * Reverts if:
     * - Some seller does not exist
     * - Some seller id is already approved
     *
     * @param _disputeResolverId - id of dispute resolver that is giving the permission
     * @param _sellerAllowList - list of seller ids added to allow list
     */
    function storeSellerAllowList(uint256 _disputeResolverId, uint256[] calldata _sellerAllowList) internal {
        // Cache protocol lookups for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        // Loop over incoming seller ids and store them to the mapping
        for (uint256 i = 0; i < _sellerAllowList.length; i++) {
            uint256 sellerId = _sellerAllowList[i];
            // Check Seller exists in sellers mapping
            (bool exists, , ) = fetchSeller(sellerId);

            // Seller must already exist
            require(exists, NO_SUCH_SELLER);

            // Seller should not be approved already
            require(lookups.allowedSellerIndex[_disputeResolverId][sellerId] == 0, SELLER_ALREADY_APPROVED);

            // Update the mappings
            lookups.allowedSellers[_disputeResolverId].push(sellerId);
            lookups.allowedSellerIndex[_disputeResolverId][sellerId] = lookups
                .allowedSellers[_disputeResolverId]
                .length; //Set index mapping. Should be index in allowedSellers array + 1
        }
    }

    /**
     * @notice Pre update dispute resolver checks
     *
     * Reverts if:
     *   - Address has already been used by another dispute resolver as operator, admin, or clerk
     *
     * @param _disputeResolverId - the id of the disputeResolver to check
     * @param _role - the address to check
     * @param _lookups - the lookups struct
     */
    function preUpdateDisputeResolverCheck(
        uint256 _disputeResolverId,
        address _role,
        ProtocolLib.ProtocolLookups storage _lookups
    ) internal view {
        // Check that the role is unique to one dispute resolver id across all roles -- not used or is used by this dispute resolver id.
        if (_role != address(0)) {
            uint256 check1 = _lookups.disputeResolverIdByOperator[_role];
            uint256 check2 = _lookups.disputeResolverIdByClerk[_role];
            uint256 check3 = _lookups.disputeResolverIdByAdmin[_role];

            require(
                (check1 == 0 || check1 == _disputeResolverId) &&
                    (check2 == 0 || check2 == _disputeResolverId) &&
                    (check3 == 0 || check3 == _disputeResolverId),
                DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE
            );
        }
    }

    /**
     * @notice Fetches a given dispute resolver pending update from storage by id
     *
     * @param _disputeResolverId - the id of the dispute resolver
     * @return exists - whether the dispute resolver pending update exists
     * @return disputeResolverPendingUpdate - the dispute resolver pending update details. See {BosonTypes.DisputeResolver}
     */
    function fetchDisputeResolverPendingUpdate(uint256 _disputeResolverId)
        internal
        view
        returns (bool exists, DisputeResolver storage disputeResolverPendingUpdate)
    {
        // Cache protocol entities for reference
        ProtocolLib.ProtocolLookups storage lookups = protocolLookups();

        // Get the dispute resolver pending update slot
        disputeResolverPendingUpdate = lookups.pendingAddressUpdatesByDisputeResolver[_disputeResolverId];

        // Determine existence
        exists =
            disputeResolverPendingUpdate.admin != address(0) ||
            disputeResolverPendingUpdate.operator != address(0) ||
            disputeResolverPendingUpdate.clerk != address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// Access Control Roles
bytes32 constant ADMIN = keccak256("ADMIN"); // Role Admin
bytes32 constant PAUSER = keccak256("PAUSER"); // Role for pausing the protocol
bytes32 constant PROTOCOL = keccak256("PROTOCOL"); // Role for facets of the ProtocolDiamond
bytes32 constant CLIENT = keccak256("CLIENT"); // Role for clients of the ProtocolDiamond
bytes32 constant UPGRADER = keccak256("UPGRADER"); // Role for performing contract and config upgrades
bytes32 constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

// Revert Reasons: Pause related
string constant NO_REGIONS_SPECIFIED = "Must specify at least one region to pause";
string constant REGION_DUPLICATED = "A region may only be specified once";
string constant ALREADY_PAUSED = "Protocol is already paused";
string constant NOT_PAUSED = "Protocol is not currently paused";
string constant REGION_PAUSED = "This region of the protocol is currently paused";

// Revert Reasons: General
string constant INVALID_ADDRESS = "Invalid address";
string constant INVALID_STATE = "Invalid state";
string constant ARRAY_LENGTH_MISMATCH = "Array length mismatch";

// Reentrancy guard
string constant REENTRANCY_GUARD = "ReentrancyGuard: reentrant call";
uint256 constant NOT_ENTERED = 1;
uint256 constant ENTERED = 2;

// Revert Reasons: Facet initializer related
string constant ALREADY_INITIALIZED = "Already initialized";

// Revert Reasons: Access related
string constant ACCESS_DENIED = "Access denied, caller doesn't have role";
string constant NOT_OPERATOR = "Not seller's operator";
string constant NOT_ADMIN = "Not admin";
string constant NOT_OPERATOR_AND_CLERK = "Not operator and clerk";
string constant NOT_ADMIN_OPERATOR_AND_CLERK = "Not admin, operator and clerk";
string constant NOT_BUYER_OR_SELLER = "Not buyer or seller";
string constant NOT_VOUCHER_HOLDER = "Not current voucher holder";
string constant NOT_BUYER_WALLET = "Not buyer's wallet address";
string constant NOT_AGENT_WALLET = "Not agent's wallet address";
string constant NOT_DISPUTE_RESOLVER_OPERATOR = "Not dispute resolver's operator address";

// Revert Reasons: Account-related
string constant NO_SUCH_SELLER = "No such seller";
string constant MUST_BE_ACTIVE = "Account must be active";
string constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";
string constant BUYER_ADDRESS_MUST_BE_UNIQUE = "Buyer address cannot be assigned to another buyer Id";
string constant DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE = "Dispute resolver address cannot be assigned to another dispute resolver Id";
string constant AGENT_ADDRESS_MUST_BE_UNIQUE = "Agent address cannot be assigned to another agent Id";
string constant NO_SUCH_BUYER = "No such buyer";
string constant NO_SUCH_AGENT = "No such agent";
string constant WALLET_OWNS_VOUCHERS = "Wallet address owns vouchers";
string constant NO_SUCH_DISPUTE_RESOLVER = "No such dispute resolver";
string constant INVALID_ESCALATION_PERIOD = "Invalid escalation period";
string constant INVALID_AMOUNT_DISPUTE_RESOLVER_FEES = "Dispute resolver fees are not present or exceed maximum dispute resolver fees in a single transaction";
string constant DUPLICATE_DISPUTE_RESOLVER_FEES = "Duplicate dispute resolver fee";
string constant DISPUTE_RESOLVER_FEE_NOT_FOUND = "Dispute resolver fee not found";
string constant SELLER_ALREADY_APPROVED = "Seller id is approved already";
string constant SELLER_NOT_APPROVED = "Seller id is not approved";
string constant INVALID_AMOUNT_ALLOWED_SELLERS = "Allowed sellers are not present or exceed maximum allowed sellers in a single transaction";
string constant INVALID_AUTH_TOKEN_TYPE = "Invalid AuthTokenType";
string constant ADMIN_OR_AUTH_TOKEN = "An admin address or an auth token is required";
string constant AUTH_TOKEN_MUST_BE_UNIQUE = "Auth token cannot be assigned to another entity of the same type";
string constant INVALID_AGENT_FEE_PERCENTAGE = "Sum of agent fee percentage and protocol fee percentage should be <= max fee percentage limit";
string constant NO_PENDING_UPDATE_FOR_ACCOUNT = "No pending updates for the given account";
string constant UNAUTHORIZED_CALLER_UPDATE = "Caller has no permission to approve this update";

// Revert Reasons: Offer related
string constant NO_SUCH_OFFER = "No such offer";
string constant OFFER_PERIOD_INVALID = "Offer period invalid";
string constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
string constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
string constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
string constant OFFER_HAS_BEEN_VOIDED = "Offer has been voided";
string constant OFFER_HAS_EXPIRED = "Offer has expired";
string constant OFFER_NOT_AVAILABLE = "Offer is not yet available";
string constant OFFER_SOLD_OUT = "Offer has sold out";
string constant CANNOT_COMMIT = "Caller cannot commit";
string constant EXCHANGE_FOR_OFFER_EXISTS = "Exchange for offer exists";
string constant AMBIGUOUS_VOUCHER_EXPIRY = "Exactly one of voucherRedeemableUntil and voucherValid must be non zero";
string constant REDEMPTION_PERIOD_INVALID = "Redemption period invalid";
string constant INVALID_DISPUTE_PERIOD = "Invalid dispute period";
string constant INVALID_RESOLUTION_PERIOD = "Invalid resolution period";
string constant INVALID_DISPUTE_RESOLVER = "Invalid dispute resolver";
string constant INVALID_QUANTITY_AVAILABLE = "Invalid quantity available";
string constant DR_UNSUPPORTED_FEE = "Dispute resolver does not accept this token";
string constant AGENT_FEE_AMOUNT_TOO_HIGH = "Sum of agent fee amount and protocol fee amount should be <= offer fee limit";

// Revert Reasons: Group related
string constant NO_SUCH_GROUP = "No such group";
string constant OFFER_NOT_IN_GROUP = "Offer not part of the group";
string constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";
string constant NOTHING_UPDATED = "Nothing updated";
string constant INVALID_CONDITION_PARAMETERS = "Invalid condition parameters";

// Revert Reasons: Exchange related
string constant NO_SUCH_EXCHANGE = "No such exchange";
string constant DISPUTE_PERIOD_NOT_ELAPSED = "Dispute period has not yet elapsed";
string constant VOUCHER_NOT_REDEEMABLE = "Voucher not yet valid or already expired";
string constant VOUCHER_EXTENSION_NOT_VALID = "Proposed date is not later than the current one";
string constant VOUCHER_STILL_VALID = "Voucher still valid";
string constant VOUCHER_HAS_EXPIRED = "Voucher has expired";
string constant TOO_MANY_EXCHANGES = "Exceeded maximum exchanges in a single transaction";
string constant EXCHANGE_IS_NOT_IN_A_FINAL_STATE = "Exchange is not in a final state";

// Revert Reasons: Twin related
string constant NO_SUCH_TWIN = "No such twin";
string constant NO_TRANSFER_APPROVED = "No transfer approved";
string constant TWIN_TRANSFER_FAILED = "Twin could not be transferred";
string constant UNSUPPORTED_TOKEN = "Unsupported token";
string constant BUNDLE_FOR_TWIN_EXISTS = "Bundle for twin exists";
string constant INVALID_SUPPLY_AVAILABLE = "supplyAvailable can't be zero";
string constant INVALID_AMOUNT = "Invalid twin amount";
string constant INVALID_TWIN_PROPERTY = "Invalid property for selected token type";
string constant INVALID_TWIN_TOKEN_RANGE = "Token range is already being used in another twin";
string constant INVALID_TOKEN_ADDRESS = "Token address is a contract that doesn't implement the interface for selected token type";

// Revert Reasons: Bundle related
string constant NO_SUCH_BUNDLE = "No such bundle";
string constant TWIN_NOT_IN_BUNDLE = "Twin not part of the bundle";
string constant OFFER_NOT_IN_BUNDLE = "Offer not part of the bundle";
string constant TOO_MANY_TWINS = "Exceeded maximum twins in a single transaction";
string constant BUNDLE_OFFER_MUST_BE_UNIQUE = "Offer must be unique to a bundle";
string constant BUNDLE_TWIN_MUST_BE_UNIQUE = "Twin must be unique to a bundle";
string constant EXCHANGE_FOR_BUNDLED_OFFERS_EXISTS = "Exchange for the bundled offers exists";
string constant INSUFFICIENT_TWIN_SUPPLY_TO_COVER_BUNDLE_OFFERS = "Insufficient twin supplyAvailable to cover total quantity of bundle offers";
string constant BUNDLE_REQUIRES_AT_LEAST_ONE_TWIN_AND_ONE_OFFER = "Bundle must have at least one twin and one offer";

// Revert Reasons: Funds related
string constant NATIVE_WRONG_ADDRESS = "Native token address must be 0";
string constant NATIVE_WRONG_AMOUNT = "Transferred value must match amount";
string constant TOKEN_NAME_UNSPECIFIED = "Token name unspecified";
string constant NATIVE_CURRENCY = "Native currency";
string constant TOO_MANY_TOKENS = "Too many tokens";
string constant TOKEN_AMOUNT_MISMATCH = "Number of amounts should match number of tokens";
string constant NOTHING_TO_WITHDRAW = "Nothing to withdraw";
string constant NOT_AUTHORIZED = "Not authorized to withdraw";
string constant TOKEN_TRANSFER_FAILED = "Token transfer failed";
string constant INSUFFICIENT_VALUE_RECEIVED = "Insufficient value received";
string constant INSUFFICIENT_AVAILABLE_FUNDS = "Insufficient available funds";
string constant NATIVE_NOT_ALLOWED = "Transfer of native currency not allowed";

// Revert Reasons: Meta-Transactions related
string constant NONCE_USED_ALREADY = "Nonce used already";
string constant FUNCTION_CALL_NOT_SUCCESSFUL = "Function call not successful";
string constant INVALID_FUNCTION_SIGNATURE = "functionSignature can not be of executeMetaTransaction method";
string constant SIGNER_AND_SIGNATURE_DO_NOT_MATCH = "Signer and signature do not match";
string constant INVALID_FUNCTION_NAME = "Invalid function name";
string constant INVALID_SIGNATURE = "Invalid signature";

// Revert Reasons: Dispute related
string constant DISPUTE_PERIOD_HAS_ELAPSED = "Dispute period has already elapsed";
string constant DISPUTE_HAS_EXPIRED = "Dispute has expired";
string constant INVALID_BUYER_PERCENT = "Invalid buyer percent";
string constant DISPUTE_STILL_VALID = "Dispute still valid";
string constant INVALID_DISPUTE_TIMEOUT = "Invalid dispute timeout";
string constant TOO_MANY_DISPUTES = "Exceeded maximum disputes in a single transaction";
string constant ESCALATION_NOT_ALLOWED = "Disputes without dispute resolver cannot be escalated";

// Revert Reasons: Config related
string constant FEE_PERCENTAGE_INVALID = "Percentage representation must be less than 10000";
string constant VALUE_ZERO_NOT_ALLOWED = "Value must be greater than 0";

// EIP712Lib
string constant PROTOCOL_NAME = "Boson Protocol";
string constant PROTOCOL_VERSION = "V2";
bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
);

// BosonVoucher
string constant VOUCHER_NAME = "Boson Voucher";
string constant VOUCHER_SYMBOL = "BOSON_VOUCHER";

// Meta Transactions - Structs
bytes32 constant META_TRANSACTION_TYPEHASH = keccak256(
    bytes(
        "MetaTransaction(uint256 nonce,address from,address contractAddress,string functionName,bytes functionSignature)"
    )
);
bytes32 constant OFFER_DETAILS_TYPEHASH = keccak256("MetaTxOfferDetails(address buyer,uint256 offerId)");
bytes32 constant META_TX_COMMIT_TO_OFFER_TYPEHASH = keccak256(
    "MetaTxCommitToOffer(uint256 nonce,address from,address contractAddress,string functionName,MetaTxOfferDetails offerDetails)MetaTxOfferDetails(address buyer,uint256 offerId)"
);
bytes32 constant EXCHANGE_DETAILS_TYPEHASH = keccak256("MetaTxExchangeDetails(uint256 exchangeId)");
bytes32 constant META_TX_EXCHANGE_TYPEHASH = keccak256(
    "MetaTxExchange(uint256 nonce,address from,address contractAddress,string functionName,MetaTxExchangeDetails exchangeDetails)MetaTxExchangeDetails(uint256 exchangeId)"
);
bytes32 constant FUND_DETAILS_TYPEHASH = keccak256(
    "MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant META_TX_FUNDS_TYPEHASH = keccak256(
    "MetaTxFund(uint256 nonce,address from,address contractAddress,string functionName,MetaTxFundDetails fundDetails)MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant DISPUTE_RESOLUTION_DETAILS_TYPEHASH = keccak256(
    "MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercentBasisPoints,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);
bytes32 constant META_TX_DISPUTE_RESOLUTIONS_TYPEHASH = keccak256(
    "MetaTxDisputeResolution(uint256 nonce,address from,address contractAddress,string functionName,MetaTxDisputeResolutionDetails disputeResolutionDetails)MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercentBasisPoints,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);

// Function names
string constant COMMIT_TO_OFFER = "commitToOffer(address,uint256)";
string constant CANCEL_VOUCHER = "cancelVoucher(uint256)";
string constant REDEEM_VOUCHER = "redeemVoucher(uint256)";
string constant COMPLETE_EXCHANGE = "completeExchange(uint256)";
string constant WITHDRAW_FUNDS = "withdrawFunds(uint256,address[],uint256[])";
string constant RETRACT_DISPUTE = "retractDispute(uint256)";
string constant RAISE_DISPUTE = "raiseDispute(uint256)";
string constant ESCALATE_DISPUTE = "escalateDispute(uint256)";
string constant RESOLVE_DISPUTE = "resolveDispute(uint256,uint256,bytes32,bytes32,uint8)";

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonAccountEvents
 *
 * @notice Defines events related to management of accounts within the protocol.
 */
interface IBosonAccountEvents {
    event SellerCreated(
        uint256 indexed sellerId,
        BosonTypes.Seller seller,
        address voucherCloneAddress,
        BosonTypes.AuthToken authToken,
        address indexed executedBy
    );
    event SellerUpdatePending(
        uint256 indexed sellerId,
        BosonTypes.Seller pendingSeller,
        BosonTypes.AuthToken pendingAuthToken,
        address indexed executedBy
    );
    event SellerUpdateApplied(
        uint256 indexed sellerId,
        BosonTypes.Seller seller,
        BosonTypes.Seller pendingSeller,
        BosonTypes.AuthToken authToken,
        BosonTypes.AuthToken pendingAuthToken,
        address indexed executedBy
    );
    event BuyerCreated(uint256 indexed buyerId, BosonTypes.Buyer buyer, address indexed executedBy);
    event BuyerUpdated(uint256 indexed buyerId, BosonTypes.Buyer buyer, address indexed executedBy);
    event AgentUpdated(uint256 indexed agentId, BosonTypes.Agent agent, address indexed executedBy);
    event DisputeResolverCreated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        BosonTypes.DisputeResolverFee[] disputeResolverFees,
        uint256[] sellerAllowList,
        address indexed executedBy
    );
    event DisputeResolverUpdatePending(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver pendingDisputeResolver,
        address indexed executedBy
    );
    event DisputeResolverUpdateApplied(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        BosonTypes.DisputeResolver pendingDisputeResolver,
        address indexed executedBy
    );
    event DisputeResolverFeesAdded(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolverFee[] disputeResolverFees,
        address indexed executedBy
    );
    event DisputeResolverFeesRemoved(
        uint256 indexed disputeResolverId,
        address[] feeTokensRemoved,
        address indexed executedBy
    );
    event AllowedSellersAdded(uint256 indexed disputeResolverId, uint256[] addedSellers, address indexed executedBy);
    event AllowedSellersRemoved(
        uint256 indexed disputeResolverId,
        uint256[] removedSellers,
        address indexed executedBy
    );
    event DisputeResolverActivated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        address indexed executedBy
    );

    event AgentCreated(uint256 indexed agentId, BosonTypes.Agent agent, address indexed executedBy);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { IAccessControl } from "../interfaces/IAccessControl.sol";
import { IDiamondCut } from "../interfaces/diamond/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Provides Diamond storage slot and supported interface checks.
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces. Also added copious code comments throughout.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. Facet management functions from original `DiamondLib` were refactored/extracted
 * to JewelerLib, since business facets also use this library for access control and
 * managing supported interfaces.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library DiamondLib {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // Maps function selectors to the facets that execute the functions
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // Array of slots of function selectors.
        // Each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implement is an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // The Boson Protocol AccessController
        IAccessControl accessController;
    }

    /**
     * @notice Gets the Diamond storage slot.
     *
     * @return ds - Diamond storage slot cast to DiamondStorage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Adds a supported interface to the Diamond.
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) internal {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as supported
        ds.supportedInterfaces[_interfaceId] = true;
    }

    /**
     * @notice Removes a supported interface from the Diamond.
     *
     * @param _interfaceId - the interface to remove
     */
    function removeSupportedInterface(bytes4 _interfaceId) internal {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as unsupported
        ds.supportedInterfaces[_interfaceId] = false;
    }

    /**
     * @notice Checks if a specific interface is supported.
     * Implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     * @return - whether or not the interface is supported
     */
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Return the value
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";
import { DiamondLib } from "../../diamond/DiamondLib.sol";
import { EIP712Lib } from "../libs/EIP712Lib.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";
import { PausableBase } from "./PausableBase.sol";
import { ReentrancyGuardBase } from "./ReentrancyGuardBase.sol";

/**
 * @title ProtocolBase
 *
 * @notice Provides domain and common modifiers to Protocol facets
 */
abstract contract ProtocolBase is PausableBase, ReentrancyGuardBase {
    /**
     * @notice Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized(bytes4 interfaceId) {
        ProtocolLib.ProtocolStatus storage ps = protocolStatus();
        require(!ps.initializedInterfaces[interfaceId], ALREADY_INITIALIZED);
        ps.initializedInterfaces[interfaceId] = true;
        _;
    }

    /**
     * @notice Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     *
     * @param _role - the role to check
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msgSender()), ACCESS_DENIED);
        _;
    }

    /**
     * @notice Get the Protocol Addresses slot
     *
     * @return pa - the Protocol Addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolLib.ProtocolAddresses storage pa) {
        pa = ProtocolLib.protocolAddresses();
    }

    /**
     * @notice Get the Protocol Limits slot
     *
     * @return pl - the Protocol Limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLib.ProtocolLimits storage pl) {
        pl = ProtocolLib.protocolLimits();
    }

    /**
     * @notice Get the Protocol Entities slot
     *
     * @return pe - the Protocol Entities slot
     */
    function protocolEntities() internal pure returns (ProtocolLib.ProtocolEntities storage pe) {
        pe = ProtocolLib.protocolEntities();
    }

    /**
     * @notice Get the Protocol Lookups slot
     *
     * @return pl - the Protocol Lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLib.ProtocolLookups storage pl) {
        pl = ProtocolLib.protocolLookups();
    }

    /**
     * @notice Get the Protocol Fees slot
     *
     * @return pf - the Protocol Fees slot
     */
    function protocolFees() internal pure returns (ProtocolLib.ProtocolFees storage pf) {
        pf = ProtocolLib.protocolFees();
    }

    /**
     * @notice Get the Protocol Counters slot
     *
     * @return pc the Protocol Counters slot
     */
    function protocolCounters() internal pure returns (ProtocolLib.ProtocolCounters storage pc) {
        pc = ProtocolLib.protocolCounters();
    }

    /**
     * @notice Get the Protocol meta-transactions storage slot
     *
     * @return pmti the Protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolLib.ProtocolMetaTxInfo storage pmti) {
        pmti = ProtocolLib.protocolMetaTxInfo();
    }

    /**
     * @notice Get the Protocol Status slot
     *
     * @return ps the Protocol Status slot
     */
    function protocolStatus() internal pure returns (ProtocolLib.ProtocolStatus storage ps) {
        ps = ProtocolLib.protocolStatus();
    }

    /**
     * @notice Gets a seller id from storage by operator address
     *
     * @param _operator - the operator address of the seller
     * @return exists - whether the seller id exists
     * @return sellerId  - the seller id
     */
    function getSellerIdByOperator(address _operator) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller id
        sellerId = protocolLookups().sellerIdByOperator[_operator];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller id from storage by admin address
     *
     * @param _admin - the admin address of the seller
     * @return exists - whether the seller id exists
     * @return sellerId  - the seller id
     */
    function getSellerIdByAdmin(address _admin) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller id
        sellerId = protocolLookups().sellerIdByAdmin[_admin];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller id from storage by clerk address
     *
     * @param _clerk - the clerk address of the seller
     * @return exists - whether the seller id exists
     * @return sellerId  - the seller id
     */
    function getSellerIdByClerk(address _clerk) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller id
        sellerId = protocolLookups().sellerIdByClerk[_clerk];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller id from storage by auth token.  A seller will have either an admin address or an auth token
     *
     * @param _authToken - the potential _authToken of the seller.
     * @return exists - whether the seller id exists
     * @return sellerId  - the seller id
     */
    function getSellerIdByAuthToken(AuthToken calldata _authToken)
        internal
        view
        returns (bool exists, uint256 sellerId)
    {
        // Get the seller id
        sellerId = protocolLookups().sellerIdByAuthToken[_authToken.tokenType][_authToken.tokenId];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a buyer id from storage by wallet address
     *
     * @param _wallet - the wallet address of the buyer
     * @return exists - whether the buyer id exists
     * @return buyerId  - the buyer id
     */
    function getBuyerIdByWallet(address _wallet) internal view returns (bool exists, uint256 buyerId) {
        // Get the buyer id
        buyerId = protocolLookups().buyerIdByWallet[_wallet];

        // Determine existence
        exists = (buyerId > 0);
    }

    /**
     * @notice Gets a agent id from storage by wallet address
     *
     * @param _wallet - the wallet address of the buyer
     * @return exists - whether the buyer id exists
     * @return agentId  - the buyer id
     */
    function getAgentIdByWallet(address _wallet) internal view returns (bool exists, uint256 agentId) {
        // Get the buyer id
        agentId = protocolLookups().agentIdByWallet[_wallet];

        // Determine existence
        exists = (agentId > 0);
    }

    /**
     * @notice Gets a dispute resolver id from storage by operator address
     *
     * @param _operator - the operator address of the dispute resolver
     * @return exists - whether the dispute resolver id exists
     * @return disputeResolverId  - the dispute resolver  id
     */
    function getDisputeResolverIdByOperator(address _operator)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver id
        disputeResolverId = protocolLookups().disputeResolverIdByOperator[_operator];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a dispute resolver id from storage by admin address
     *
     * @param _admin - the admin address of the dispute resolver
     * @return exists - whether the dispute resolver id exists
     * @return disputeResolverId  - the dispute resolver id
     */
    function getDisputeResolverIdByAdmin(address _admin)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver id
        disputeResolverId = protocolLookups().disputeResolverIdByAdmin[_admin];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a dispute resolver id from storage by clerk address
     *
     * @param _clerk - the clerk address of the dispute resolver
     * @return exists - whether the dispute resolver id exists
     * @return disputeResolverId  - the dispute resolver id
     */
    function getDisputeResolverIdByClerk(address _clerk)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver id
        disputeResolverId = protocolLookups().disputeResolverIdByClerk[_clerk];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a group id from storage by offer id
     *
     * @param _offerId - the offer id
     * @return exists - whether the group id exists
     * @return groupId  - the group id.
     */
    function getGroupIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 groupId) {
        // Get the group id
        groupId = protocolLookups().groupIdByOffer[_offerId];

        // Determine existence
        exists = (groupId > 0);
    }

    /**
     * @notice Fetches a given seller from storage by id
     *
     * @param _sellerId - the id of the seller
     * @return exists - whether the seller exists
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     */
    function fetchSeller(uint256 _sellerId)
        internal
        view
        returns (
            bool exists,
            Seller storage seller,
            AuthToken storage authToken
        )
    {
        // Cache protocol entities for reference
        ProtocolLib.ProtocolEntities storage entities = protocolEntities();

        // Get the seller's slot
        seller = entities.sellers[_sellerId];

        //Get the seller's auth token's slot
        authToken = entities.authTokens[_sellerId];

        // Determine existence
        exists = (_sellerId > 0 && seller.id == _sellerId);
    }

    /**
     * @notice Fetches a given buyer from storage by id
     *
     * @param _buyerId - the id of the buyer
     * @return exists - whether the buyer exists
     * @return buyer - the buyer details. See {BosonTypes.Buyer}
     */
    function fetchBuyer(uint256 _buyerId) internal view returns (bool exists, BosonTypes.Buyer storage buyer) {
        // Get the buyer's slot
        buyer = protocolEntities().buyers[_buyerId];

        // Determine existence
        exists = (_buyerId > 0 && buyer.id == _buyerId);
    }

    /**
     * @notice Fetches a given dispute resolver from storage by id
     *
     * @param _disputeResolverId - the id of the dispute resolver
     * @return exists - whether the dispute resolver exists
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     * @return disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     */
    function fetchDisputeResolver(uint256 _disputeResolverId)
        internal
        view
        returns (
            bool exists,
            BosonTypes.DisputeResolver storage disputeResolver,
            BosonTypes.DisputeResolverFee[] storage disputeResolverFees
        )
    {
        // Cache protocol entities for reference
        ProtocolLib.ProtocolEntities storage entities = protocolEntities();

        // Get the dispute resolver's slot
        disputeResolver = entities.disputeResolvers[_disputeResolverId];

        //Get dispute resolver's fee list slot
        disputeResolverFees = entities.disputeResolverFees[_disputeResolverId];

        // Determine existence
        exists = (_disputeResolverId > 0 && disputeResolver.id == _disputeResolverId);
    }

    /**
     * @notice Fetches a given agent from storage by id
     *
     * @param _agentId - the id of the agent
     * @return exists - whether the agent exists
     * @return agent - the agent details. See {BosonTypes.Agent}
     */
    function fetchAgent(uint256 _agentId) internal view returns (bool exists, BosonTypes.Agent storage agent) {
        // Get the agent's slot
        agent = protocolEntities().agents[_agentId];

        // Determine existence
        exists = (_agentId > 0 && agent.id == _agentId);
    }

    /**
     * @notice Fetches a given offer from storage by id
     *
     * @param _offerId - the id of the offer
     * @return exists - whether the offer exists
     * @return offer - the offer details. See {BosonTypes.Offer}
     */
    function fetchOffer(uint256 _offerId) internal view returns (bool exists, Offer storage offer) {
        // Get the offer's slot
        offer = protocolEntities().offers[_offerId];

        // Determine existence
        exists = (_offerId > 0 && offer.id == _offerId);
    }

    /**
     * @notice Fetches the offer dates from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDates - the offer dates details. See {BosonTypes.OfferDates}
     */
    function fetchOfferDates(uint256 _offerId) internal view returns (BosonTypes.OfferDates storage offerDates) {
        // Get the offerDates slot
        offerDates = protocolEntities().offerDates[_offerId];
    }

    /**
     * @notice Fetches the offer durations from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDurations - the offer durations details. See {BosonTypes.OfferDurations}
     */
    function fetchOfferDurations(uint256 _offerId)
        internal
        view
        returns (BosonTypes.OfferDurations storage offerDurations)
    {
        // Get the offer's slot
        offerDurations = protocolEntities().offerDurations[_offerId];
    }

    /**
     * @notice Fetches the dispute resolution terms from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return disputeResolutionTerms - the details about the dispute resolution terms. See {BosonTypes.DisputeResolutionTerms}
     */
    function fetchDisputeResolutionTerms(uint256 _offerId)
        internal
        view
        returns (BosonTypes.DisputeResolutionTerms storage disputeResolutionTerms)
    {
        // Get the disputeResolutionTerms slot
        disputeResolutionTerms = protocolEntities().disputeResolutionTerms[_offerId];
    }

    /**
     * @notice Fetches a given group from storage by id
     *
     * @param _groupId - the id of the group
     * @return exists - whether the group exists
     * @return group - the group details. See {BosonTypes.Group}
     */
    function fetchGroup(uint256 _groupId) internal view returns (bool exists, Group storage group) {
        // Get the group's slot
        group = protocolEntities().groups[_groupId];

        // Determine existence
        exists = (_groupId > 0 && group.id == _groupId);
    }

    /**
     * @notice Fetches the Condition from storage by group id
     *
     * @param _groupId - the id of the group
     * @return condition - the condition details. See {BosonTypes.Condition}
     */
    function fetchCondition(uint256 _groupId) internal view returns (BosonTypes.Condition storage condition) {
        // Get the offerDates slot
        condition = protocolEntities().conditions[_groupId];
    }

    /**
     * @notice Fetches a given exchange from storage by id
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - whether the exchange exists
     * @return exchange - the exchange details. See {BosonTypes.Exchange}
     */
    function fetchExchange(uint256 _exchangeId) internal view returns (bool exists, Exchange storage exchange) {
        // Get the exchange's slot
        exchange = protocolEntities().exchanges[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && exchange.id == _exchangeId);
    }

    /**
     * @notice Fetches a given voucher from storage by exchange id
     *
     * @param _exchangeId - the id of the exchange associated with the voucher
     * @return voucher - the voucher details. See {BosonTypes.Voucher}
     */
    function fetchVoucher(uint256 _exchangeId) internal view returns (Voucher storage voucher) {
        // Get the voucher
        voucher = protocolEntities().vouchers[_exchangeId];
    }

    /**
     * @notice Fetches a given dispute from storage by exchange id
     *
     * @param _exchangeId - the id of the exchange associated with the dispute
     * @return exists - whether the dispute exists
     * @return dispute - the dispute details. See {BosonTypes.Dispute}
     */
    function fetchDispute(uint256 _exchangeId)
        internal
        view
        returns (
            bool exists,
            Dispute storage dispute,
            DisputeDates storage disputeDates
        )
    {
        // Cache protocol entities for reference
        ProtocolLib.ProtocolEntities storage entities = protocolEntities();

        // Get the dispute's slot
        dispute = entities.disputes[_exchangeId];

        // Get the disputeDates slot
        disputeDates = entities.disputeDates[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && dispute.exchangeId == _exchangeId);
    }

    /**
     * @notice Fetches a given twin from storage by id
     *
     * @param _twinId - the id of the twin
     * @return exists - whether the twin exists
     * @return twin - the twin details. See {BosonTypes.Twin}
     */
    function fetchTwin(uint256 _twinId) internal view returns (bool exists, Twin storage twin) {
        // Get the twin's slot
        twin = protocolEntities().twins[_twinId];

        // Determine existence
        exists = (_twinId > 0 && twin.id == _twinId);
    }

    /**
     * @notice Fetches a given bundle from storage by id
     *
     * @param _bundleId - the id of the bundle
     * @return exists - whether the bundle exists
     * @return bundle - the bundle details. See {BosonTypes.Bundle}
     */
    function fetchBundle(uint256 _bundleId) internal view returns (bool exists, Bundle storage bundle) {
        // Get the bundle's slot
        bundle = protocolEntities().bundles[_bundleId];

        // Determine existence
        exists = (_bundleId > 0 && bundle.id == _bundleId);
    }

    /**
     * @notice Gets offer from protocol storage, makes sure it exist and not voided
     *
     * Reverts if:
     * - Offer does not exist
     * - Offer already voided
     * - Caller is not the seller
     *
     *  @param _offerId - the id of the offer to check
     */
    function getValidOffer(uint256 _offerId) internal view returns (Offer storage offer) {
        bool exists;
        Seller storage seller;

        // Get offer
        (exists, offer) = fetchOffer(_offerId);

        // Offer must already exist
        require(exists, NO_SUCH_OFFER);

        // Offer must not already be voided
        require(!offer.voided, OFFER_HAS_BEEN_VOIDED);

        // Get seller, we assume seller exists if offer exists
        (, seller, ) = fetchSeller(offer.sellerId);

        // Caller must be seller's operator address
        require(seller.operator == msgSender(), NOT_OPERATOR);
    }

    /**
     * @notice Gets the bundle id for a given offer id.
     *
     * @param _offerId - the offer id.
     * @return exists - whether the bundle id exists
     * @return bundleId  - the bundle id.
     */
    function fetchBundleIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 bundleId) {
        // Get the bundle id
        bundleId = protocolLookups().bundleIdByOffer[_offerId];

        // Determine existence
        exists = (bundleId > 0);
    }

    /**
     * @notice Gets the bundle id for a given twin id.
     *
     * @param _twinId - the twin id.
     * @return exists - whether the bundle id exist
     * @return bundleId  - the bundle id.
     */
    function fetchBundleIdByTwin(uint256 _twinId) internal view returns (bool exists, uint256 bundleId) {
        // Get the bundle id
        bundleId = protocolLookups().bundleIdByTwin[_twinId];

        // Determine existence
        exists = (bundleId > 0);
    }

    /**
     * @notice Gets the exchange ids for a given offer id.
     *
     * @param _offerId - the offer id.
     * @return exists - whether the exchange Ids exist
     * @return exchangeIds  - the exchange Ids.
     */
    function getExchangeIdsByOffer(uint256 _offerId)
        internal
        view
        returns (bool exists, uint256[] storage exchangeIds)
    {
        // Get the exchange Ids
        exchangeIds = protocolLookups().exchangeIdsByOffer[_offerId];

        // Determine existence
        exists = (exchangeIds.length > 0);
    }

    /**
     * @notice Make sure the caller is buyer associated with the exchange
     *
     * Reverts if
     * - caller is not the buyer associated with exchange
     *
     * @param _currentBuyer - id of current buyer associated with the exchange
     */
    function checkBuyer(uint256 _currentBuyer) internal view {
        // Get the caller's buyer account id
        (, uint256 buyerId) = getBuyerIdByWallet(msgSender());

        // Must be the buyer associated with the exchange (which is always voucher holder)
        require(buyerId == _currentBuyer, NOT_VOUCHER_HOLDER);
    }

    /**
     * @notice Get a valid exchange and its associated voucher
     *
     * Reverts if
     * - Exchange does not exist
     * - Exchange is not in the expected state
     *
     * @param _exchangeId - the id of the exchange to complete
     * @param _expectedState - the state the exchange should be in
     * @return exchange - the exchange
     * @return voucher - the voucher
     */
    function getValidExchange(uint256 _exchangeId, ExchangeState _expectedState)
        internal
        view
        returns (Exchange storage exchange, Voucher storage voucher)
    {
        // Get the exchange
        bool exchangeExists;
        (exchangeExists, exchange) = fetchExchange(_exchangeId);

        // Make sure the exchange exists
        require(exchangeExists, NO_SUCH_EXCHANGE);
        // Make sure the exchange is in expected state
        require(exchange.state == _expectedState, INVALID_STATE);

        // Get the voucher
        voucher = fetchVoucher(_exchangeId);
    }

    /**
     * @notice Returns the current sender address.
     */
    function msgSender() internal view returns (address) {
        return EIP712Lib.msgSender();
    }

    /**
     * @notice Gets the agent id for a given offer id.
     *
     * @param _offerId - the offer id.
     * @return exists - whether the exchange id exist
     * @return agentId - the agent id.
     */
    function fetchAgentIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 agentId) {
        // Get the agent id
        agentId = protocolLookups().agentIdByOffer[_offerId];

        // Determine existence
        exists = (agentId > 0);
    }

    /**
     * @notice Fetches the offer fees from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerFees - the offer fees details. See {BosonTypes.OfferFees}
     */
    function fetchOfferFees(uint256 _offerId) internal view returns (BosonTypes.OfferFees storage offerFees) {
        // Get the offerFees slot
        offerFees = protocolEntities().offerFees[_offerId];
    }

    /**
     * @notice Fetches a list of twin receipts from storage by exchange id
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - whether one or more twin receipt exists
     * @return twinReceipts - the list of twin receipts. See {BosonTypes.TwinReceipt}
     */
    function fetchTwinReceipts(uint256 _exchangeId)
        internal
        view
        returns (bool exists, TwinReceipt[] storage twinReceipts)
    {
        // Get the twin receipts slot
        twinReceipts = protocolLookups().twinReceiptsByExchange[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && twinReceipts.length > 0);
    }

    /**
     * @notice Fetches a condition from storage by exchange id
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - whether one condition exists for the exchange
     * @return condition - the condition. See {BosonTypes.Condition}
     */
    function fetchConditionByExchange(uint256 _exchangeId)
        internal
        view
        returns (bool exists, Condition storage condition)
    {
        // Get the condition slot
        condition = protocolLookups().exchangeCondition[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && condition.method != EvaluationMethod.None);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title ProtocolLib
 *
 * @notice Provides access to the protocol addresses, limits, entities, fees, counters, initializers and  metaTransactions slots for Facets.
 */
library ProtocolLib {
    bytes32 internal constant PROTOCOL_ADDRESSES_POSITION = keccak256("boson.protocol.addresses");
    bytes32 internal constant PROTOCOL_LIMITS_POSITION = keccak256("boson.protocol.limits");
    bytes32 internal constant PROTOCOL_ENTITIES_POSITION = keccak256("boson.protocol.entities");
    bytes32 internal constant PROTOCOL_LOOKUPS_POSITION = keccak256("boson.protocol.lookups");
    bytes32 internal constant PROTOCOL_FEES_POSITION = keccak256("boson.protocol.fees");
    bytes32 internal constant PROTOCOL_COUNTERS_POSITION = keccak256("boson.protocol.counters");
    bytes32 internal constant PROTOCOL_STATUS_POSITION = keccak256("boson.protocol.initializers");
    bytes32 internal constant PROTOCOL_META_TX_POSITION = keccak256("boson.protocol.metaTransactions");

    // Protocol addresses storage
    struct ProtocolAddresses {
        // Address of the Boson Protocol treasury
        address payable treasury;
        // Address of the Boson Token (ERC-20 contract)
        address payable token;
        // Address of the Boson Protocol Voucher beacon
        address voucherBeacon;
        // Address of the Boson Beacon proxy implementation
        address beaconProxy;
    }

    // Protocol limits storage
    struct ProtocolLimits {
        // limit on the resolution period that a seller can specify
        uint256 maxResolutionPeriod;
        // limit on the escalation response period that a dispute resolver can specify
        uint256 maxEscalationResponsePeriod;
        // lower limit for dispute period
        uint256 minDisputePeriod;
        // limit how many exchanges can be processed in single batch transaction
        uint16 maxExchangesPerBatch;
        // limit how many offers can be added to the group
        uint16 maxOffersPerGroup;
        // limit how many offers can be added to the bundle
        uint16 maxOffersPerBundle;
        // limit how many twins can be added to the bundle
        uint16 maxTwinsPerBundle;
        // limit how many offers can be processed in single batch transaction
        uint16 maxOffersPerBatch;
        // limit how many different tokens can be withdrawn in a single transaction
        uint16 maxTokensPerWithdrawal;
        // limit how many dispute resolver fee structs can be processed in a single transaction
        uint16 maxFeesPerDisputeResolver;
        // limit how many disputes can be processed in single batch transaction
        uint16 maxDisputesPerBatch;
        // limit how many sellers can be added to or removed from an allow list in a single transaction
        uint16 maxAllowedSellers;
        // limit the sum of (protocol fee percentage + agent fee percentage) of an offer fee
        uint16 maxTotalOfferFeePercentage;
        // limit the max royalty percentage that can be set by the seller
        uint16 maxRoyaltyPecentage;
    }

    // Protocol fees storage
    struct ProtocolFees {
        // Percentage that will be taken as a fee from the net of a Boson Protocol exchange
        uint256 percentage; // 1.75% = 175, 100% = 10000
        // Flat fee taken for exchanges in $BOSON
        uint256 flatBoson;
        // buyer escalation deposit percentage
        uint256 buyerEscalationDepositPercentage;
    }

    // Protocol entities storage
    struct ProtocolEntities {
        // offer id => offer
        mapping(uint256 => BosonTypes.Offer) offers;
        // offer id => offer dates
        mapping(uint256 => BosonTypes.OfferDates) offerDates;
        // offer id => offer fees
        mapping(uint256 => BosonTypes.OfferFees) offerFees;
        // offer id => offer durations
        mapping(uint256 => BosonTypes.OfferDurations) offerDurations;
        // offer id => dispute resolution terms
        mapping(uint256 => BosonTypes.DisputeResolutionTerms) disputeResolutionTerms;
        // exchange id => exchange
        mapping(uint256 => BosonTypes.Exchange) exchanges;
        // exchange id => voucher
        mapping(uint256 => BosonTypes.Voucher) vouchers;
        // exchange id => dispute
        mapping(uint256 => BosonTypes.Dispute) disputes;
        // exchange id => dispute dates
        mapping(uint256 => BosonTypes.DisputeDates) disputeDates;
        // seller id => seller
        mapping(uint256 => BosonTypes.Seller) sellers;
        // buyer id => buyer
        mapping(uint256 => BosonTypes.Buyer) buyers;
        // dispute resolver id => dispute resolver
        mapping(uint256 => BosonTypes.DisputeResolver) disputeResolvers;
        // dispute resolver id => dispute resolver fee array
        mapping(uint256 => BosonTypes.DisputeResolverFee[]) disputeResolverFees;
        // agent id => agent
        mapping(uint256 => BosonTypes.Agent) agents;
        // group id => group
        mapping(uint256 => BosonTypes.Group) groups;
        // group id => condition
        mapping(uint256 => BosonTypes.Condition) conditions;
        // bundle id => bundle
        mapping(uint256 => BosonTypes.Bundle) bundles;
        // twin id => twin
        mapping(uint256 => BosonTypes.Twin) twins;
        //entity id => auth token
        mapping(uint256 => BosonTypes.AuthToken) authTokens;
    }

    // Protocol lookups storage
    struct ProtocolLookups {
        // offer id => exchange ids
        mapping(uint256 => uint256[]) exchangeIdsByOffer;
        // offer id => bundle id
        mapping(uint256 => uint256) bundleIdByOffer;
        // twin id => bundle id
        mapping(uint256 => uint256) bundleIdByTwin;
        // offer id => group id
        mapping(uint256 => uint256) groupIdByOffer;
        // offer id => agent id
        mapping(uint256 => uint256) agentIdByOffer;
        // seller operator address => sellerId
        mapping(address => uint256) sellerIdByOperator;
        // seller admin address => sellerId
        mapping(address => uint256) sellerIdByAdmin;
        // seller clerk address => sellerId
        mapping(address => uint256) sellerIdByClerk;
        // buyer wallet address => buyerId
        mapping(address => uint256) buyerIdByWallet;
        // dispute resolver operator address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByOperator;
        // dispute resolver admin address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByAdmin;
        // dispute resolver clerk address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByClerk;
        // dispute resolver id to fee token address => index of the token address
        mapping(uint256 => mapping(address => uint256)) disputeResolverFeeTokenIndex;
        // agent wallet address => agentId
        mapping(address => uint256) agentIdByWallet;
        // account id => token address => amount
        mapping(uint256 => mapping(address => uint256)) availableFunds;
        // account id => all tokens with balance > 0
        mapping(uint256 => address[]) tokenList;
        // account id => token address => index on token addresses list
        mapping(uint256 => mapping(address => uint256)) tokenIndexByAccount;
        // seller id => cloneAddress
        mapping(uint256 => address) cloneAddress;
        // buyer id => number of active vouchers
        mapping(uint256 => uint256) voucherCount;
        // buyer address => groupId => commit count (addresses that have committed to conditional offers)
        mapping(address => mapping(uint256 => uint256)) conditionalCommitsByAddress;
        // AuthTokenType => Auth NFT contract address.
        mapping(BosonTypes.AuthTokenType => address) authTokenContracts;
        // AuthTokenType => tokenId => sellerId
        mapping(BosonTypes.AuthTokenType => mapping(uint256 => uint256)) sellerIdByAuthToken;
        // seller id => token address (only ERC721) => start and end of token ids range
        mapping(uint256 => mapping(address => BosonTypes.TokenRange[])) twinRangesBySeller;
        // seller id => token address (only ERC721) => twin ids
        mapping(uint256 => mapping(address => uint256[])) twinIdsByTokenAddressAndBySeller;
        // exchange id => BosonTypes.TwinReceipt
        mapping(uint256 => BosonTypes.TwinReceipt[]) twinReceiptsByExchange;
        // dispute resolver id => list of allowed sellers
        mapping(uint256 => uint256[]) allowedSellers;
        // dispute resolver id => seller id => index of allowed seller in allowedSellers
        mapping(uint256 => mapping(uint256 => uint256)) allowedSellerIndex;
        // exchange id => condition
        mapping(uint256 => BosonTypes.Condition) exchangeCondition;
        // groupId => offerId => index on Group.offerIds array
        mapping(uint256 => mapping(uint256 => uint256)) offerIdIndexByGroup;
        // seller id => Seller
        mapping(uint256 => BosonTypes.Seller) pendingAddressUpdatesBySeller;
        // seller id => AuthToken
        mapping(uint256 => BosonTypes.AuthToken) pendingAuthTokenUpdatesBySeller;
        // dispute resolver id => DisputeResolver
        mapping(uint256 => BosonTypes.DisputeResolver) pendingAddressUpdatesByDisputeResolver;
    }

    // Incrementing id counters
    struct ProtocolCounters {
        // Next account id
        uint256 nextAccountId;
        // Next offer id
        uint256 nextOfferId;
        // Next exchange id
        uint256 nextExchangeId;
        // Next twin id
        uint256 nextTwinId;
        // Next group id
        uint256 nextGroupId;
        // Next twin id
        uint256 nextBundleId;
    }

    // Storage related to Meta Transactions
    struct ProtocolMetaTxInfo {
        // The current sender address associated with the transaction
        address currentSenderAddress;
        // A flag that tells us whether the current transaction is a meta-transaction or a regular transaction.
        bool isMetaTransaction;
        // The domain Separator of the protocol
        bytes32 domainSeparator;
        // address => nonce => nonce used indicator
        mapping(address => mapping(uint256 => bool)) usedNonce;
        // The cached chain id
        uint256 cachedChainId;
        // map function name to input type
        mapping(string => BosonTypes.MetaTxInputType) inputType;
        // map input type => hash info
        mapping(BosonTypes.MetaTxInputType => BosonTypes.HashInfo) hashInfo;
    }

    // Individual facet initialization states
    struct ProtocolStatus {
        // the current pause scenario, a sum of PausableRegions as powers of two
        uint256 pauseScenario;
        // reentrancy status
        uint256 reentrancyStatus;
        // interface id => initialized?
        mapping(bytes4 => bool) initializedInterfaces;
    }

    /**
     * @dev Gets the protocol addresses slot
     *
     * @return pa - the protocol addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolAddresses storage pa) {
        bytes32 position = PROTOCOL_ADDRESSES_POSITION;
        assembly {
            pa.slot := position
        }
    }

    /**
     * @notice Gets the protocol limits slot
     *
     * @return pl - the protocol limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLimits storage pl) {
        bytes32 position = PROTOCOL_LIMITS_POSITION;
        assembly {
            pl.slot := position
        }
    }

    /**
     * @notice Gets the protocol entities slot
     *
     * @return pe - the protocol entities slot
     */
    function protocolEntities() internal pure returns (ProtocolEntities storage pe) {
        bytes32 position = PROTOCOL_ENTITIES_POSITION;
        assembly {
            pe.slot := position
        }
    }

    /**
     * @notice Gets the protocol lookups slot
     *
     * @return pl - the protocol lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLookups storage pl) {
        bytes32 position = PROTOCOL_LOOKUPS_POSITION;
        assembly {
            pl.slot := position
        }
    }

    /**
     * @notice Gets the protocol fees slot
     *
     * @return pf - the protocol fees slot
     */
    function protocolFees() internal pure returns (ProtocolFees storage pf) {
        bytes32 position = PROTOCOL_FEES_POSITION;
        assembly {
            pf.slot := position
        }
    }

    /**
     * @notice Gets the protocol counters slot
     *
     * @return pc - the protocol counters slot
     */
    function protocolCounters() internal pure returns (ProtocolCounters storage pc) {
        bytes32 position = PROTOCOL_COUNTERS_POSITION;
        assembly {
            pc.slot := position
        }
    }

    /**
     * @notice Gets the protocol meta-transactions storage slot
     *
     * @return pmti - the protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolMetaTxInfo storage pmti) {
        bytes32 position = PROTOCOL_META_TX_POSITION;
        assembly {
            pmti.slot := position
        }
    }

    /**
     * @notice Gets the protocol status slot
     *
     * @return ps - the the protocol status slot
     */
    function protocolStatus() internal pure returns (ProtocolStatus storage ps) {
        bytes32 position = PROTOCOL_STATUS_POSITION;
        assembly {
            ps.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

/**
 * @title BosonTypes
 *
 * @notice Enums and structs used by the Boson Protocol contract ecosystem.
 */

contract BosonTypes {
    enum PausableRegion {
        Offers,
        Twins,
        Bundles,
        Groups,
        Sellers,
        Buyers,
        DisputeResolvers,
        Agents,
        Exchanges,
        Disputes,
        Funds,
        Orchestration,
        MetaTransaction
    }

    enum EvaluationMethod {
        None, // None should always be at index 0. Never change this value.
        Threshold,
        SpecificToken
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed,
        Disputed
    }

    enum DisputeState {
        Resolving,
        Retracted,
        Resolved,
        Escalated,
        Decided,
        Refused
    }

    enum TokenType {
        FungibleToken,
        NonFungibleToken,
        MultiToken
    } // ERC20, ERC721, ERC1155

    enum MetaTxInputType {
        Generic,
        CommitToOffer,
        Exchange,
        Funds,
        RaiseDispute,
        ResolveDispute
    }

    enum AuthTokenType {
        None,
        Custom, // For future use
        Lens,
        ENS
    }

    enum SellerUpdateFields {
        Admin,
        Operator,
        Clerk,
        AuthToken
    }

    enum DisputeResolverUpdateFields {
        Admin,
        Operator,
        Clerk
    }

    struct AuthToken {
        uint256 tokenId;
        AuthTokenType tokenType;
    }

    struct Seller {
        uint256 id;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        bool active;
    }

    struct Buyer {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct DisputeResolver {
        uint256 id;
        uint256 escalationResponsePeriod;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        string metadataUri;
        bool active;
    }

    struct DisputeResolverFee {
        address tokenAddress;
        string tokenName;
        uint256 feeAmount;
    }

    struct Agent {
        uint256 id;
        uint256 feePercentage;
        address payable wallet;
        bool active;
    }

    struct DisputeResolutionTerms {
        uint256 disputeResolverId;
        uint256 escalationResponsePeriod;
        uint256 feeAmount;
        uint256 buyerEscalationDeposit;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        address exchangeToken;
        string metadataUri;
        string metadataHash;
        bool voided;
    }

    struct OfferDates {
        uint256 validFrom;
        uint256 validUntil;
        uint256 voucherRedeemableFrom;
        uint256 voucherRedeemableUntil;
    }

    struct OfferDurations {
        uint256 disputePeriod;
        uint256 voucherValid;
        uint256 resolutionPeriod;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
    }

    struct Condition {
        EvaluationMethod method;
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
        uint256 maxCommits;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        uint256 finalizedDate;
        ExchangeState state;
    }

    struct Voucher {
        uint256 committedDate;
        uint256 validUntilDate;
        uint256 redeemedDate;
        bool expired;
    }

    struct Dispute {
        uint256 exchangeId;
        uint256 buyerPercent;
        DisputeState state;
    }

    struct DisputeDates {
        uint256 disputed;
        uint256 escalated;
        uint256 finalized;
        uint256 timeout;
    }

    struct Receipt {
        uint256 exchangeId;
        uint256 offerId;
        uint256 buyerId;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        OfferFees offerFees;
        uint256 agentId;
        address exchangeToken;
        uint256 finalizedDate;
        Condition condition;
        uint256 committedDate;
        uint256 redeemedDate;
        bool voucherExpired;
        uint256 disputeResolverId;
        uint256 disputedDate;
        uint256 escalatedDate;
        DisputeState disputeState;
        TwinReceipt[] twinReceipts;
    }

    struct TokenRange {
        uint256 start;
        uint256 end;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 amount; // ERC1155 / ERC20 (amount to be transferred to each buyer on redemption)
        uint256 supplyAvailable; // all
        uint256 tokenId; // ERC1155 / ERC721 (must be initialized with the initial pointer position of the ERC721 ids available range)
        address tokenAddress; // all
        TokenType tokenType;
    }

    struct TwinReceipt {
        uint256 twinId;
        uint256 tokenId; // only for ERC721 and ERC1155
        uint256 amount; // only for ERC1155 and ERC20
        address tokenAddress;
        TokenType tokenType;
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }

    struct Funds {
        address tokenAddress;
        string tokenName;
        uint256 availableAmount;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        bytes functionSignature;
    }

    struct HashInfo {
        bytes32 typeHash;
        function(bytes memory) internal pure returns (bytes32) hashFunction;
    }

    struct OfferFees {
        uint256 protocolFee;
        uint256 agentFee;
    }

    struct VoucherInitValues {
        string contractURI;
        uint256 royaltyPercentage;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.9;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title IDiamondCut
 *
 * @notice Manages Diamond Facets.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Cuts facets of the Diamond.
     *
     * Adds/replaces/removes any number of function selectors.
     *
     * If populated, _calldata is executed with delegatecall on _init
     *
     * Reverts if caller does not have UPGRADER role
     *
     * @param _facetCuts - contains the facet addresses and function selectors
     * @param _init - the address of the contract or facet to execute _calldata
     * @param _calldata - a function call, including function selector and arguments
     */
    function diamondCut(
        FacetCut[] calldata _facetCuts,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";

/**
 * @title EIP712Lib
 *
 * @dev Provides the domain separator and chain id.
 */
library EIP712Lib {
    /**
     * @notice Generates the domain separator hash.
     * @dev Using the chainId as the salt enables the client to be active on one chain
     * while a metatx is signed for a contract on another chain. That could happen if the client is,
     * for instance, a metaverse scene that runs on one chain while the contracts it interacts with are deployed on another chain.
     *
     * @param _name - the name of the protocol
     * @param _version -  The version of the protocol
     * @return the domain separator hash
     */
    function buildDomainSeparator(string memory _name, string memory _version) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(_name)),
                    keccak256(bytes(_version)),
                    address(this),
                    block.chainid
                )
            );
    }

    /**
     * @notice Recovers the Signer from the Signature components.
     *
     * Reverts if:
     * - Signer is the zero address
     *
     * @param _user  - the sender of the transaction
     * @param _hashedMetaTx - hashed meta transaction
     * @param _sigR - r part of the signer's signature
     * @param _sigS - s part of the signer's signature
     * @param _sigV - v part of the signer's signature
     * @return true if signer is same as _user parameter
     */
    function verify(
        address _user,
        bytes32 _hashedMetaTx,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) internal returns (bool) {
        // Ensure signature is unique
        // See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/04695aecbd4d17dddfd55de766d10e3805d6f42f/contracts/cryptography/ECDSA.sol#63
        require(
            uint256(_sigS) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 &&
                (_sigV == 27 || _sigV == 28),
            INVALID_SIGNATURE
        );

        address signer = ecrecover(toTypedMessageHash(_hashedMetaTx), _sigV, _sigR, _sigS);
        require(signer != address(0), INVALID_SIGNATURE);
        return signer == _user;
    }

    /**
     * @notice Gets the domain separator from storage if matches with the chain id and diamond address, else, build new domain separator.
     *
     * @return the domain separator
     */
    function getDomainSeparator() private returns (bytes32) {
        ProtocolLib.ProtocolMetaTxInfo storage pmti = ProtocolLib.protocolMetaTxInfo();
        uint256 cachedChainId = pmti.cachedChainId;

        if (block.chainid == cachedChainId) {
            return pmti.domainSeparator;
        } else {
            bytes32 domainSeparator = buildDomainSeparator(PROTOCOL_NAME, PROTOCOL_VERSION);
            pmti.domainSeparator = domainSeparator;
            pmti.cachedChainId = block.chainid;

            return domainSeparator;
        }
    }

    /**
     * @notice Generates EIP712 compatible message hash.
     *
     * @dev Accepts message hash and returns hash message in EIP712 compatible form
     * so that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     *
     * @param _messageHash  - the message hash
     * @return the EIP712 compatible message hash
     */
    function toTypedMessageHash(bytes32 _messageHash) internal returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), _messageHash));
    }

    /**
     * @notice Gets the current message sender address from storage.
     *
     * @return the the current message sender address from storage
     */
    function getCurrentSenderAddress() internal view returns (address) {
        return ProtocolLib.protocolMetaTxInfo().currentSenderAddress;
    }

    /**
     * @notice Returns the message sender address.
     *
     * @dev Could be msg.sender or the message sender address from storage (in case of meta transaction).
     *
     * @return the message sender address
     */
    function msgSender() internal view returns (address) {
        bool isItAMetaTransaction = ProtocolLib.protocolMetaTxInfo().isMetaTransaction;

        // Get sender from the storage if this is a meta transaction
        if (isItAMetaTransaction) {
            address sender = getCurrentSenderAddress();
            require(sender != address(0), INVALID_ADDRESS);

            return sender;
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title PausableBase
 *
 * @notice Provides modifiers for regional pausing
 */
contract PausableBase is BosonTypes {
    /**
     * @notice Modifier that checks the Offers region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier offersNotPaused() {
        revertIfPaused(PausableRegion.Offers);
        _;
    }

    /**
     * @notice Modifier that checks the Twins region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier twinsNotPaused() {
        revertIfPaused(PausableRegion.Twins);
        _;
    }

    /**
     * @notice Modifier that checks the Bundles region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier bundlesNotPaused() {
        revertIfPaused(PausableRegion.Bundles);
        _;
    }

    /**
     * @notice Modifier that checks the Groups region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier groupsNotPaused() {
        revertIfPaused(PausableRegion.Groups);
        _;
    }

    /**
     * @notice Modifier that checks the Sellers region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier sellersNotPaused() {
        revertIfPaused(PausableRegion.Sellers);
        _;
    }

    /**
     * @notice Modifier that checks the Buyers region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier buyersNotPaused() {
        revertIfPaused(PausableRegion.Buyers);
        _;
    }

    /**
     * @notice Modifier that checks the Agents region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier agentsNotPaused() {
        revertIfPaused(PausableRegion.Agents);
        _;
    }

    /**
     * @notice Modifier that checks the DisputeResolvers region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier disputeResolversNotPaused() {
        revertIfPaused(PausableRegion.DisputeResolvers);
        _;
    }

    /**
     * @notice Modifier that checks the Exchanges region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier exchangesNotPaused() {
        revertIfPaused(PausableRegion.Exchanges);
        _;
    }

    /**
     * @notice Modifier that checks the Disputes region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier disputesNotPaused() {
        revertIfPaused(PausableRegion.Disputes);
        _;
    }

    /**
     * @notice Modifier that checks the Funds region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier fundsNotPaused() {
        revertIfPaused(PausableRegion.Funds);
        _;
    }

    /**
     * @notice Modifier that checks the Orchestration region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier orchestrationNotPaused() {
        revertIfPaused(PausableRegion.Orchestration);
        _;
    }

    /**
     * @notice Modifier that checks the MetaTransaction region is not paused
     *
     * Reverts if region is paused
     *
     * See: {BosonTypes.PausableRegion}
     */
    modifier metaTransactionsNotPaused() {
        revertIfPaused(PausableRegion.MetaTransaction);
        _;
    }

    /**
     * @notice Checks if a region of the protocol is paused.
     *
     * Reverts if region is paused
     *
     * @param _region the region to check pause status for
     */
    function revertIfPaused(PausableRegion _region) internal view {
        // Region enum value must be used as the exponent in a power of 2
        uint256 powerOfTwo = 1 << uint256(_region);
        require((ProtocolLib.protocolStatus().pauseScenario & powerOfTwo) != powerOfTwo, REGION_PAUSED);
    }
}

// SPDX-License-Identifier: MIT

import "../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";

pragma solidity 0.8.9;

/**
 * @notice Contract module that helps prevent reentrant calls to a function.
 *
 * The majority of code, comments and general idea is taken from OpenZeppelin implementation.
 * Code was adjusted to work with the storage layout used in the protocol.
 * Reference implementation: OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * @dev Because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardBase {
    /**
     * @notice Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        ProtocolLib.ProtocolStatus storage ps = ProtocolLib.protocolStatus();
        // On the first call to nonReentrant, ps.reentrancyStatus will be NOT_ENTERED
        require(ps.reentrancyStatus != ENTERED, REENTRANCY_GUARD);

        // Any calls to nonReentrant after this point will fail
        ps.reentrancyStatus = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        ps.reentrancyStatus = NOT_ENTERED;
    }
}