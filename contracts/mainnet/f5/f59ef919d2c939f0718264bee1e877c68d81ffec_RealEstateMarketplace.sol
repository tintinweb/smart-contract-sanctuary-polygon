/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// Importowanie niezbędnych bibliotek
pragma solidity ^0.8.0;

// Deklaracja kontraktu
contract RealEstateMarketplace {
    
    // Struktura przechowująca informacje o każdym z mieszkań
    struct Property {
        uint id;
        string name;
        string location;
        uint size;
        uint price;
        address payable owner;
        uint endTime;
    }
    
    // Tablica przechowująca wszystkie nieruchomości
    Property[] public properties;
    
    // Zdarzenie emitowane po zakończeniu aukcji
    event PropertySold(uint propertyId, address buyer, uint price);
    
    // Funkcja dodająca nową nieruchomość do tablicy
    function addProperty(string memory _name, string memory _location, uint _size, uint _price) public {
        require(_size > 0 && _price > 0, "Size and price must be greater than 0");
        uint endTime = block.timestamp + 30 days; // Aukcja trwa 30 dni od daty dodania nieruchomości
        properties.push(Property(properties.length, _name, _location, _size, _price, payable(msg.sender), endTime));
    }
    
    // Funkcja zwracająca ilość nieruchomości na sprzedaż
    function getPropertyCount() public view returns (uint) {
        return properties.length;
    }
    
    // Funkcja zwracająca informacje o nieruchomości o podanym ID
    function getPropertyById(uint _id) public view returns (uint, string memory, string memory, uint, uint, address, uint) {
        Property memory property = properties[_id];
        return (property.id, property.name, property.location, property.size, property.price, property.owner, property.endTime);
    }
    
    // Funkcja wywoływana przy zakupie nieruchomości
    function buyProperty(uint _id) public payable {
        Property storage property = properties[_id];
        require(block.timestamp < property.endTime, "Aukcja zakonczona");
        require(msg.value == property.price, "Nieprawidlowa cena");
        property.owner.transfer(msg.value);
        emit PropertySold(_id, msg.sender, msg.value);
        property.owner = payable(msg.sender);
        property.endTime = block.timestamp + 30 days; // Odnowienie aukcji
    }
}