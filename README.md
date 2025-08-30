The long overdue collectivization of food shopping meets Tinder. A project to organize our food runs during school breaks.

### You can:
- Create and manage accounts
  - Register via email
  - Link a google account
  - Delete your account and all associated data
- Join and create groups with your account
- Browse the catalogue of a store
- Put things from a store in your cart
- Start a store run
  - Pick up things from your cart and that of others in your group using intuitive Tinder-inspired cards
- View your transaction history
  - See what you bought
  - See what you bought others (and how much of that each person still owes you)
    - Mark something as paid as soon as that person gave you the money
  - See what others bought for you (and how much you still owe them)


# Installation

You can download the latest pre-release [here](https://github.com/wanjawischmeier/pizza-flizza/releases/download/v0.4.3/pizza_v0.4.3.apk) (only for testing).


# Privacy
Whether you want to delete your account or just remove all associated data, feel free to do so [here](https://wanjawischmeier.github.io/pizza-flizza/pages/account-management) :)

You can find the privacy policy [here](https://wanjawischmeier.github.io/pizza-flizza/pages/privacy-policy/de).


# Screenshots
<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/a2831ca8-c294-4c30-9623-2bc070db9534" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/286813e0-1ca8-4189-85d7-bb4bc4ff887c" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/bc9510ea-aadb-40e9-b908-3364057fed5b" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/766c6886-bfda-457e-b0ad-c2eaaa8a8199" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/23182457-dbdd-45e2-8359-01ddc6d5b734" height="500"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/89806548-3f4e-4a2a-8ddd-88f74b834abb" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/6685b2e4-9f68-4370-b1bd-004c29a49b38" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/f0f9d0e6-0d12-4898-86f7-e15158854530" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/b522ebc2-20b6-453d-ab5a-5dcb2f82f4ed" height="500"></td>
    <td><img src="https://github.com/user-attachments/assets/699dff26-0c24-4a00-9a99-6d49d452d296" height="500"></td>
  </tr>
</table>


# Backend database
Using [Google Firebase](https://firebase.google.com) for realtime storage and account management. Below is the basic structure of the database:
```plaintext
Database
├── groups
│   ├── <group_id>
│   │   ├── name: <group_name>
│   │   └── users
│   │       ├── <user_id>: <user_name>
│   │       └── ...
│   └── ...
├── shops
│   ├── <shop_id>
│   │   ├── name: <shop_name>
│   │   ├── address: <shop_address>
│   │   └── items
│   │       ├── <category_id>
│   │       │   ├── 0_name: <category_name>
│   │       │   └── <item_id>
│   │       │       ├── bought: <number_bought>
│   │       │       ├── name: <item_name>
│   │       │       └── price: <item_price>
│   │       └── ...
│   └── ...
├── users
│   ├── <group_id>
│   │   ├── <user_id>
│   │   │   ├── fulfilled
│   │   │   │   ├── <shop_id>
│   │   │   │   │   ├── <other_user_id>
│   │   │   │   │   │   ├── <item_id>
│   │   │   │   │   │   │   ├── count: <count>
│   │   │   │   │   │   │   └── timestamp: <timestamp>
│   │   │   ├── history
│   │   │   │   ├── <shop_id>
│   │   │   │   │   ├── <timestamp>
│   │   │   │   │   │   ├── <item_id>: <count>
│   │   │   ├── orders
│   │   │   │   ├── <shop_id>
│   │   │   │   │   ├── <item_id>
│   │   │   │   │   │   ├── count: <count>
│   │   │   │   │   │   └── timestamp: <timestamp>
│   │   │   └── stats
│   │   │       ├── <shop_id>
│   │   │       │   ├── <category_id>
│   │   │       │   │   ├── <item_id>: <count>
│   │   │       └── ...
│   └── ...
└── version_hints
    ├── <version_number>
    │   └── type: <type_number>
    ├── depricated: <version_number>
    └── disabled: <version_number>
```
