class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :name
      t.string :confirmed_at
      t.string :confirm_token
      t.string :token

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :token, unique: true
    add_index :users, :confirm_token, unique: true
  end
end
