// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract RentMannagementSystem {
    struct User {
        string Name;
        address UserAddress;
        bool isOwner; //owner 1 / Tenant 0
    }

    struct Property {
        address ownerAddress;
        string propertyAddress;
        string propertyType; //ev veya dükkan
        bool contractValidityStatus;
    }

    struct RentContract {
        address ownerAddress;
        address tenantAddress;
        string propertyAddress;
        string propertyType; //ev veya dükkan
        uint contractStartDate;
        uint contractFinishDate;
        bool validityStatus ;
        bool earlyTerminate;
    }

    mapping(address => User) public userInformations;
    mapping(string => Property) public propertyInformations;
    mapping(uint => RentContract) public contractInformations;

    function createUser(string memory _name, bool _isOwner) public {
        //The user who wants to register is checked from the user list
        require(userInformations[msg.sender].UserAddress == address(0), "User is already registered"); 
        userInformations[msg.sender] = User(_name, msg.sender, _isOwner);
    }

    function addProperty(string memory _propertyAddress, string memory _propertyType) public {
        //The existence of the address to perform the transaction is checked from the user list.
        require(userInformations[msg.sender].UserAddress != address(0), "User not found");
        //Is the user who will make the addition a host?
        require(userInformations[msg.sender].isOwner, "Tenants can't add properties");
        //Is there a landlord address in the list where the property address is registered?
        require(propertyInformations[_propertyAddress].ownerAddress == address(0), "Property already exists");
        propertyInformations[_propertyAddress] = Property(msg.sender, _propertyAddress, _propertyType, false);
    }

    function contractStart(address _tenantAddress, string memory _propertyAddress, string memory _propertyType, uint _contractStartDate, uint _contractFinishDate) public {
        require(userInformations[msg.sender].UserAddress != address(0), "User not found");
        require(userInformations[msg.sender].isOwner, "Tenants cannot initiate a contract");
        require(propertyInformations[_propertyAddress].ownerAddress != address(0), "Property not found");

        uint contractID = uint(keccak256(abi.encodePacked(msg.sender, _propertyAddress, _contractStartDate, _contractFinishDate)));

        contractInformations[contractID] = RentContract(msg.sender, _tenantAddress,  _propertyAddress, _propertyType, _contractStartDate, _contractFinishDate, true, false);
    }
}