$signature = @'
using System;
using System.Windows.Forms;

public class MessageEventArgs : EventArgs
{
    public int Msg { get; set; }
    public IntPtr WParam { get; set; }
    public IntPtr LParam { get; set; }
    public IntPtr Result { get; set; }
    public bool Handled { get; set; }

    public MessageEventArgs(Message m)
    {
        this.Msg = m.Msg;
        this.WParam = m.WParam;
        this.LParam = m.LParam;
        this.Result = m.Result;
        this.Handled = false;
    }
}

public class WndProcForm : Form
{
    /// <summary>
    /// Raised for every window message. Handlers may set e.Handled = true and e.Result to suppress default processing.
    /// </summary>
    public event EventHandler<MessageEventArgs> MessageReceived;

    public WndProcForm()
    {
        // Optional: set any default form properties here
    }

    protected override void WndProc(ref Message m)
    {
        var args = new MessageEventArgs(m);

        // Invoke any subscribers
        try
        {
            MessageReceived?.Invoke(this, args);
        }
        catch
        {
            // swallow exceptions from handlers to avoid crashing the message loop
        }

        // If handler marked the message as handled, apply the Result and skip base processing
        if (args.Handled)
        {
            m.Result = args.Result;
            return;
        }

        base.WndProc(ref m);
    }
}
'@

Add-Type -WarningAction "Ignore" -IgnoreWarnings -TypeDefinition $signature -Language CSharp -ReferencedAssemblies @("$($dependencyPath)\System.Windows.Forms.dll","$($dependencyPath)\System.ComponentModel.Primitives.dll","$($dependencyPath)\System.Windows.Forms.Primitives.dll","$($dependencyPath)\System.Drawing.Primitives.dll","$($dependencyPath)\System.Drawing.dll","$($dependencyPath)\System.Drawing.Common.dll","$($dependencyPath)\System.Private.Windows.Core.dll")