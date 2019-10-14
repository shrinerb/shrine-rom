Container.boot(:persistence) do
  init do
    require "rom"
    require "rom-sql"
  end

  start do
    database_url = Container[:config].database_url

    rom = ROM.container(:sql, database_url) do |config|
      config.auto_registration Container.root.join("lib/persistence")
    end

    Container.register("persistence.rom", rom)
  end

  stop do
    Container["persistence.rom"].disconnect
  end
end
