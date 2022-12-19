// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Sample_URIRouter {
    // Init total routes.
    uint256 public totalRoutes;
    // Init items per route.
    uint256 public itemsPerRoute;
    // Mapping of index: uint256 to cid: string
    mapping(uint256 => string) public routes;
    
    function lookup(uint256 itemIndex) public view returns (string memory) {
        /// https://docs.soliditylang.org/en/v0.8.13/types.html#division
        // Since the type of the result of an operation is always the type of one of the operands,
        // division on integers always results in an integer. In Solidity, division rounds towards zero.
        /// Example:
        /// routes[0] => "ipfs://firstCID"
        /// routes[1] => "ipfs://secondCID"
        /// itemsPerRoute = 100
        // If `itemIndex` = 0; 0/100 = 0 (index #0)
        // If `itemIndex` = 50; 50/100 = 0.5 = 0 (index #0)
        // If `itemIndex` = 100; 100/100 = 1 (index #1)
        // If `itemIndex` = 199; 199/100 = 1.99 (index #1)
        uint256 index = itemIndex / itemsPerRoute;
        
        // Get cid: string based on index: uint256
        string memory uri = routes[index];
    
        return uri;
    }

    function registerRoute(uint256 index, string calldata uri) public {
        // Assign `uri` as value to `index` as key for routes mapping.
        routes[index] = uri;
        // Assign += 1 to _totalRoutes.
        totalRoutes += 1;
    }

    function setItemsPerRoute(uint256 _itemsPerRoute) public {
        itemsPerRoute = _itemsPerRoute;
    }
}