use iced::{Point, Size};

#[derive(Debug, Clone, Copy)]
pub struct AppCanvas {
    pub canvas_size: Size,
    pub cell_size: Size,
    pub zoom: f32,
}

impl AppCanvas {
    pub fn width(self: &Self) -> f32 {
        self.canvas_size.width * self.zoom * self.cell_size().height
    }

    pub fn height(self: &Self) -> f32 {
        self.canvas_size.height * self.zoom * self.cell_size().width
    }

    pub fn cell_size(self: &Self) -> Size {
        Size::new(
            self.cell_size.width * self.zoom,
            self.cell_size.height * self.zoom,
        )
    }
}
