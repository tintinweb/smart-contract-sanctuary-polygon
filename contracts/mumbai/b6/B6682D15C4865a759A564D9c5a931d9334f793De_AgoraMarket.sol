// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AgoraMarket {
    uint8 constant MINERAL_PRICE_DECIMAL = 18;
    uint256 planetCounter = 0;

    struct Planet {
        address payable owner;
        uint256 mineral;
        uint256 supply;
    }

    // Spices entires are stored in the mineralPriceMap
    // Keys of the map are mineral/spice identifiers
    mapping(uint256 => uint256) mineralPriceMap;
    mapping(uint256 => Planet) planetMap;
    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    event AddPlanet(
        uint256 indexed planetIndex,
        uint256 mineralIndex,
        uint256 supply
    );
    event UpdateMineralPrice(uint256 indexed mineralIndex, uint256 price);
    event UpdatePlanetSupply(uint256 indexed planetIndex, uint256 supply);
    event PurchaseMineral(
        uint256 indexed planetIndex,
        uint256 indexed mineralIndex,
        uint256 price
    );

    constructor() {
        owner = payable(msg.sender);
        mineralPriceMap[0] = 1 * 10**16; // 0.01 ETH
        mineralPriceMap[1] = 2 * 10**16; // 0.02 ETH
        mineralPriceMap[2] = 3 * 10**16; // 0.03 ETH
        mineralPriceMap[3] = 4 * 10**16; // 0.04 ETH
    }

    function addPlanet(uint256 _mineral, uint256 _supply) public onlyOwner {
        planetMap[planetCounter] = Planet({
            owner: payable(msg.sender),
            mineral: _mineral,
            supply: _supply
        });

        emit AddPlanet(planetCounter, _mineral, _supply);
        planetCounter++;
    }

    function getPlanet(uint256 _planetIndex)
        external
        view
        returns (Planet memory)
    {
        return planetMap[_planetIndex];
    }

    function getAllPlanets() external view returns (Planet[] memory) {
        Planet[] memory planets = new Planet[](planetCounter);
        for (uint256 i = 0; i < planetCounter; i++) {
            planets[i] = Planet({
                owner: planetMap[i].owner,
                mineral: planetMap[i].mineral,
                supply: planetMap[i].supply
            });
        }
        return planets;
    }

    function getMineral(uint256 _mineralIndex) external view returns (uint256) {
        return mineralPriceMap[_mineralIndex];
    }

    function updateMineralPrice(uint256 _mineralIndex, uint256 price) public {
        require(_mineralIndex < 4, "Not a valid mineral");
        mineralPriceMap[_mineralIndex] = price;
        emit UpdateMineralPrice(_mineralIndex, price);
    }

    function updatePlanetSupply(uint256 _planetIndex, uint256 supply) public {
        require(_planetIndex < planetCounter, "Not a valid planet market");
        planetMap[_planetIndex].supply = supply;
        emit UpdatePlanetSupply(_planetIndex, supply);
    }

    function purchaseMineralFromPlanet(
        uint256 _planetIndex,
        uint256 _mineralIndex,
        uint256 _quantity
    ) public payable {
        require(_planetIndex < planetCounter, "Not a valid planet market");
        require(_mineralIndex < 4, "Not a valid mineral index");

        uint256 mineralPrice = mineralPriceMap[_mineralIndex];
        require(mineralPrice < msg.sender.balance, "Not enough balance");

        Planet storage planet = planetMap[_planetIndex];
        require(_quantity <= planet.supply, "Not enough supply");

        // charge eth
        require(msg.value == mineralPrice * _quantity, "Wrong amount");

        // All's good
        planet.supply -= _quantity;

        emit PurchaseMineral(_planetIndex, _mineralIndex, _quantity);
    }

    receive() external payable {}
}