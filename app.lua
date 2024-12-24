drv = require 'luasql.postgres'
lgi = require 'lgi'

glib = lgi.GLib
gtk = lgi.Gtk
cairo = lgi.cairo

pixbuf = lgi.GdkPixbuf.Pixbuf
loader = lgi.GdkPixbuf.PixbufLoader

gtk.init()


bld = gtk.Builder()
bld:add_from_file('ui.glade')

ui = bld.objects


env = drv.postgres()
con = env:connect('host=fxnode.ru port=5432 dbname=labs user=labuser password=labpassword')

cur = con:execute('SELECT * FROM exam04.weather ORDER BY year, month, day;')

temp = {}

row = cur:fetch({}, 'a')
while row do
	f = io.open('icons/' .. row['icon'] .. '.svg', 'rb')
	svg = f:read('*a')
	f:close()

	dec = loader()
	dec:write(svg, #svg, nil)
	dec:close(nil)

	icon = dec:get_pixbuf()
	date = string.format('%d-%02d-%02d', row['year'], row['month'], row['day'])

	table.insert(temp, row['temp_lo'] * 0.5 + row['temp_hi'] * 0.5)

	itr = ui.mdl:append()
	ui.mdl[itr] = {[1] = date, [2] = icon, [3] = row['temp_lo'], [4] = row['temp_hi'], [5] = row['feels_like'], [6] = row['water_temp'], [7] = row['humidity'], [8] = row['pressure'], [9] = row['wind_speed'], [10] = row['wind_dir']}

	row = cur:fetch({}, 'a')
end


function on_cnv_draw(wgt, ctx)
	ctx:set_source_rgb(1.0, 1.0, 1.0)
	ctx:paint()

	w = 512
	h = 128

	s = w / #temp

	for i = 0, #temp - 1 do
		t = temp[i + 1] * 10

		if t < 0 then
			ctx:rectangle(i * s, h / 2, s - 2, -t)
			print(t)
		else
			ctx:rectangle(i * s, h / 2 - t, s - 2, t)
		end

		ctx:set_source_rgb(1.0, 0.80, 0.95)
		ctx:fill()
	end

	ctx:move_to(0, h / 2)
	ctx:line_to(w, h / 2)
	ctx:set_source_rgba(0.0, 0.0, 0.0, 0.5)
	ctx:stroke()

end

function on_wnd_close(wgt)
	gtk.main_quit()
end

tab = {}
tab['on_cnv_draw'] = on_cnv_draw
tab['on_wnd_destroy'] = on_wnd_close

bld:connect_signals(tab)


ui.wnd:show_all()

gtk.main()

con:close()
env:close()