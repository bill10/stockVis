import numpy as np
from bokeh.plotting import figure
from bokeh.models import Plot, ColumnDataSource, Range1d
from bokeh.properties import Instance
from bokeh.server.app import bokeh_app
from bokeh.server.utils.plugins import object_page
from bokeh.models.widgets import HBox, Slider, TextInput, VBoxForm, VBox
from multiprocessing import Pool,Process,Queue
import os
import sys
import subprocess
import pandas as pd


class StockApp(VBox):
    extra_generated_classes = [["StockApp", "StockApp", "VBox"]]
    text = Instance(TextInput)
    plot = Instance(Plot)
    source = Instance(ColumnDataSource)

    @classmethod
    def create(cls):
        """One-time creation of app's objects.
        This function is called once, and is responsible for
        creating all objects (plots, datasources, etc)"""
        obj = cls()
        obj.source = ColumnDataSource({'Time':[], 'Price':[], 'Size':[]})
        obj.text = TextInput(value="", title="Symbol:")
        # Generate a figure container
        plot = figure(x_axis_type = "datetime",
                      plot_width=900,plot_height=300)
                      #tools="pan,box_zoom,reset,resize,crosshair")
        # Plot the line by the x,y values in the source property
        plot.line('Time', 'Price', source=obj.source)
        obj.plot = plot
        obj.children.append(obj.text)
        obj.children.append(obj.plot)
        return obj

    def setup_events(self):
        """Attaches the on_change event to the value property of the widget.
        The callback is set to the input_change method of this app."""
        super(StockApp, self).setup_events()
        if not self.text:
            return
        # Text box event registration
        self.text.on_change('value', self, 'input_change')

    def input_change(self, obj, attrname, old, new):
        """Executes whenever the input form changes.
        It is responsible for updating the plot, or anything else you want.
        Args:
            obj : the object that changed
            attrname : the attr that changed
            old : old value of attr
            new : new value of attr
        """
        print("Pulling {}...".format(new))
        def load_data(files,q):
            for f in files:
                if not os.path.exists(f):
                    print("Downloading {}".format(f))
                    sys.stdout.flush()
                    _,s,t = f.split('/')
                    if not os.path.exists("Data/"+s):
                        os.makedirs("Data/"+s)
                    subprocess.call(['scp', '-q', '-r', 'osg:/home/bill10/stash/public/Stock/{}.KP/e{}'.format(t,s),'Data/{}/{}'.format(s,t)])
                if not os.path.exists(f):
                    q.put(pd.DataFrame(columns=['Time', 'Price', 'Size']))
                else:
                    df=pd.read_csv(f, header=None,
                        usecols=[1,2,6,8],
                        parse_dates={'Time':[1,2]})
                    df.columns=['Time', 'Price', 'Size']
                    q.put(df)
        q=Queue()
        files=["Data/{}/201004{:0>2}".format(new,i) for i in range(1,2)]
        chunks=10
        if len(files)<chunks:
            chunksize=1
        else:
            chunksize=int(np.ceil(len(files)*1.0/chunks))
        jobs=[Process(target=load_data, args=(files[i:i+chunksize],q), name='stockapp') for i in xrange(0, len(files), chunksize)]
        for p in jobs: 
            p.start()
        res=0
        df=pd.DataFrame({'Time':[], 'Price':[], 'Size':[]})
        while res<len(files):
            df=df.append(q.get())
            res+=1
        for p in jobs:
            p.join()
        self.source.data=df.sort('Time').to_dict('list')
        #self.plot.y_range.start=df['Price'].min()
        #self.plot.y_range.end=df['Price'].max()
        self.plot.line('Time','Price',source=self.source)

# The following code adds a "/bokeh/sliders/" url to the bokeh-server. This
# URL will render this sine wave sliders app. If you don't want to serve this
# applet from a Bokeh server (for instance if you are embedding in a separate
# Flask application), then just remove this block of code.
@bokeh_app.route("/stocks/")
@object_page("stocks")
def make_sliders():
    app = StockApp.create()
    return app