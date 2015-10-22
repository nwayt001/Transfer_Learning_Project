using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Windows;

namespace RSVP_Feedback_WPF
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application, System.IDisposable
    {
        [STAThread]
        public static void Main()
        {
            using (var application = new App())
            {
                application.InitializeComponent();
                application.Run();
            }
        }

        public void Dispose()
        {
            System.Environment.Exit(1);
        }

    }
}
