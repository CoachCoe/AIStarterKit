---
name: upgradeable-contracts
description: "OpenZeppelin UUPS proxy patterns for upgradeable contracts. Triggers: upgradeable, proxy, UUPS, upgrade"
---

# OpenZeppelin UUPS Upgradeable Contracts

## When to Activate

- Implementing upgradeable smart contracts
- Using UUPS proxy pattern
- Setting up proxy deployment scripts
- Upgrading existing proxy contracts

## Context
Use when implementing upgradeable contracts with OpenZeppelin UUPS pattern.

## Dependencies

Install OpenZeppelin upgradeable contracts:

```bash
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

Add to foundry.toml remappings:

```toml
remappings = [
    "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/",
    "@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/"
]
```

## Inheritance Order

CRITICAL: Always inherit in this exact order to avoid linearization issues:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MyContract is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    // Contract implementation
}
```

## Initializer Pattern

```solidity
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

/// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();
}

function initialize(address admin) public initializer {
    __AccessControl_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(ADMIN_ROLE, admin);
}
```

## Upgrade Authorization

```solidity
function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(ADMIN_ROLE)
{}
```

## Proxy Deployment with Foundry

```solidity
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// In deployment script:
function run() public {
    vm.startBroadcast();

    // 1. Deploy implementation
    MyContract implementation = new MyContract();

    // 2. Encode initializer call
    bytes memory initData = abi.encodeCall(
        MyContract.initialize,
        (admin)
    );

    // 3. Deploy proxy pointing to implementation
    ERC1967Proxy proxy = new ERC1967Proxy(
        address(implementation),
        initData
    );

    // 4. Cast proxy address to implementation type for interaction
    MyContract myContract = MyContract(address(proxy));

    vm.stopBroadcast();

    // Log addresses
    console.log("Implementation:", address(implementation));
    console.log("Proxy:", address(proxy));
}
```

## Storage Layout Rules

1. **Never remove existing state variables**
2. **Never reorder existing state variables**
3. **Only append new variables at the end**
4. **Use storage gaps for future flexibility**:

```solidity
// Reserve 50 slots for future upgrades
uint256[50] private __gap;
```

## Upgrading Contracts

```solidity
// Deploy new implementation
MyContractV2 newImpl = new MyContractV2();

// Upgrade proxy to new implementation
MyContract(proxyAddress).upgradeToAndCall(
    address(newImpl),
    "" // or encoded call for re-initialization
);
```

## Common Mistakes to Avoid

1. **Calling initializer in constructor**: Never do this, use `initializer` modifier
2. **Forgetting parent initializers**: Must call ALL `__X_init()` functions
3. **Wrong inheritance order**: Causes initialization failures
4. **Missing `_disableInitializers()`**: Security vulnerability
5. **Storage collisions**: Always append, never insert or remove
6. **Initializing in wrong order**: Match inheritance order

## Anti-Patterns (FORBIDDEN)

| Pattern | Why Forbidden | Instead |
|---------|---------------|---------|
| Initialize in constructor | Proxy won't receive initialization | MUST use `initializer` modifier |
| Skip `_disableInitializers()` | Implementation can be hijacked | MUST disable in constructor |
| Remove/reorder state variables | Storage layout collision | MUST only append new variables |
| Use `Ownable` for upgrades | Single point of failure | MUST use `AccessControl` with roles |
| Deploy implementation directly | Bypasses proxy pattern | MUST deploy via ERC1967Proxy |
| Forget `__gap` in base contracts | Blocks future upgrades | MUST reserve 50 storage slots |
| Skip parent `__X_init()` calls | Uninitialized state | MUST call ALL parent initializers |
| Use `delegatecall` manually | Storage corruption risk | MUST use UUPS upgrade mechanism |

---

## Verification (REQUIRED before marking complete)

```bash
# Contracts compile
forge build

# All tests pass (including proxy tests)
forge test -vvv

# Verify upgrade works
forge test --match-test "Upgrade"
```

### Checklist

- [ ] Contract inherits from correct upgradeable bases
- [ ] `_disableInitializers()` in constructor
- [ ] `initialize()` has `initializer` modifier
- [ ] All parent `__X_init()` functions called
- [ ] `uint256[50] __gap` added for storage expansion
- [ ] `_authorizeUpgrade()` restricts to admin role
- [ ] Tests use proxy address, not implementation
- [ ] Upgrade tests verify state preservation
