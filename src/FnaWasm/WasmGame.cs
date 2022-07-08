using Microsoft.Xna.Framework;

namespace FnaWasm
{
    class WasmGame : Game
    {
        private readonly GraphicsDeviceManager graphics;

        public WasmGame()
        {
            graphics = new GraphicsDeviceManager(this);
        }

        protected override void Draw(GameTime gameTime)
        {
            graphics.GraphicsDevice.Clear(Color.CornflowerBlue);
        }
    }
}